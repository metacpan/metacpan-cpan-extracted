package Database::BI::Controller::Dashboard;

our $VERSION = '0.005.2';

use Mojo::Base 'Mojolicious::Controller', -strict, -signatures;

use Carp		qw(croak carp);
use List::Util		qw(min max sum);
use CGI::Info;
use CGI::Lingua;
use Mojo::File;
use Mojo::JSON		qw(encode_json);
use Mojo::Util		qw(url_escape encode);
use File::Temp		qw(tempfile tempdir);
use Readonly;
use Socket		qw(inet_aton);
use Sub::Protected;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# File extensions that Database::Abstraction can probe, in probe order.
# Note: D::A uses ".sql" for SQLite -- NOT ".sqlite".
Readonly my @SUPPORTED_EXT => qw( csv db sql xml psv );
# Use \z (absolute end-of-string) not $ (which permits a trailing \n before \z).
# A query param decoded from "file.csv%0A" has basename "sales.csv\n"; without \z
# that passes the extension guard and reaches realpath with an embedded newline.
Readonly my $EXT_RE        => do { my $p = join '|', @SUPPORTED_EXT; qr/\.(?:$p)\z/i };

# Table name safe-identifier pattern -- must match DataSource's TABLE_NAME_RE
# exactly: first character must be a letter or underscore (not a digit), so
# that every table name the controller accepts can also be opened by DataSource
# without an unhandled croak.
Readonly my $TABLE_NAME_RE => qr/\A[A-Za-z_][A-Za-z0-9_]*\z/;

# URL spec pattern shared by _open_spec and _spec_to_url.
# qr{} delimiter avoids the \/ escaping noise required by the // form.
# /s: makes . match \n so a percent-decoded newline inside a URL does not
# silently truncate the captured URL before the \z end-of-string anchor.
Readonly my $URL_SPEC_RE   => qr{\Aurl:(https?://.+)\z}si;

# ---------------------------------------------------------------------------
# I18N message dictionary for all user-visible strings in this controller.
# To plug in a Locale::Maketext backend, extend _i18n() below.
# ---------------------------------------------------------------------------

Readonly my %MESSAGES => (
	error_table_invalid    => 'Invalid table name "%s"',
	error_table_open       => 'Could not open table "%s": %s',
	error_file_open        => 'Could not open "%s": %s',
	error_no_path          => 'No path specified',
	error_not_found        => 'File or directory not found: %s',
	error_dir_not_found    => 'Directory not found: %s',
	error_write_failed     => 'Write failed: %s',
	error_ext_required     => 'Use a .csv, .sql, or .json filename extension',
	error_upload_none      => 'No file received',
	error_upload_ext       => 'Unsupported file type. Accepted: CSV, PSV, XML, SQLite (.sql)',
	error_upload_too_large => 'File too large (maximum %s MiB)',
	error_path_required    => '"path" parameter is required',
	error_url_required     => 'Please enter a URL',
	error_url_invalid      => '"%s" is not a valid http:// or https:// URL',
	error_url_fetch        => 'Could not load HTML table from "%s": %s',
	error_url_ssrf         => '"%s" resolves to a private or reserved address and cannot be fetched',
);

# Maximum accepted upload body size.  Enforced both here (application layer)
# and via Mojolicious max_request_size (transport layer) set in startup().
# Must match $MAX_REQUEST_SIZE in BI.pm.
Readonly my $MAX_UPLOAD_MIB   => 50;
Readonly my $MAX_UPLOAD_BYTES => $MAX_UPLOAD_MIB * 1_048_576;

# ---------------------------------------------------------------------------
# Protected helpers
# ---------------------------------------------------------------------------

# _i18n($self, $key, @sprintf_args) -> $string
#
# Purpose: Look up a user-visible string from %MESSAGES and apply sprintf
#          for positional arguments.  The entry point for future i18n
#          backend integration (e.g. Locale::Maketext).
# Entry:   $key must be a key in %MESSAGES; @args are sprintf positionals.
# Exit:    Returns the formatted string, or a fallback containing $key.
sub _i18n :Protected ($self, $key, @args) {
	my $tmpl = $MESSAGES{$key} // return "Internal error: unknown message key '$key'";
	return @args ? sprintf($tmpl, @args) : $tmpl;
}

# _is_safe_url($url) -> bool
#
# Purpose: SSRF guard.  Blocks the most dangerous classes of Server-Side Request
#          Forgery targets: loopback aliases (localhost, 127/8) and literal
#          private/link-local/CGNAT IPv4 addresses in the URL host component.
#
# Design rationale for scope:
#   Resolving hostnames via DNS and checking the result is ineffective: a
#   separate DNS lookup happens at LWP connect time (TOCTOU / DNS rebinding
#   window).  The authoritative defence against hostname-based SSRF is a
#   network-layer egress firewall.  This function handles the Perl-layer
#   interception for the most common patterns that operators cannot easily
#   filter at the network level: bare loopback aliases and literal private IPs
#   hard-coded by an attacker.
#
# Blocked targets:
#   localhost / 127.0.0.0/8 / 0.0.0.0 / ::1  -- loopback aliases
#   10.0.0.0/8    -- RFC 1918 private (literal IP)
#   172.16.0.0/12 -- RFC 1918 private (literal IP)
#   192.168.0.0/16-- RFC 1918 private (literal IP)
#   169.254.0.0/16-- link-local; AWS/GCP/Azure metadata endpoint (literal IP)
#   100.64.0.0/10 -- CGNAT / Tailscale shared space (literal IP)
#
# Hostname-based targets (e.g. http://internal.corp.example.com/) are allowed
# at this layer; block them with egress firewall rules instead.
sub _is_safe_url {
	my ($url) = @_;
	return 0 unless $url =~ m{\Ahttps?://([^/:?\[\]#]+)}i;
	my $host = lc $1;

	# Block well-known loopback aliases.
	return 0 if $host eq 'localhost'
	          || $host =~ /\A127\./
	          || $host eq '0.0.0.0'
	          || $host eq '::1';

	# For literal IPv4 addresses only: check private/link-local/CGNAT ranges.
	# Skipping DNS for hostname targets avoids a live network call in tests and
	# removes the TOCTOU window that makes DNS-resolved checks illusory anyway.
	return 1 unless $host =~ /\A\d{1,3}(?:\.\d{1,3}){3}\z/;

	my $packed = inet_aton($host) or return 1;
	my $n = unpack 'N', $packed;

	return 0 if ($n & 0xFF000000) == 0x0A000000;	# 10/8
	return 0 if ($n & 0xFFF00000) == 0xAC100000;	# 172.16/12
	return 0 if ($n & 0xFFFF0000) == 0xC0A80000;	# 192.168/16
	return 0 if ($n & 0xFFFF0000) == 0xA9FE0000;	# 169.254/16 (link-local / metadata)
	return 0 if ($n & 0xFFC00000) == 0x64400000;	# 100.64/10 (CGNAT)
	return 1;
}

# _resolve_template($self) -> ($platform, $language)
#
# Purpose: Read platform and language from config, then resolve the Accept-Language
#          header to a language code -- falling back to the config default when
#          no template directory exists for the resolved language.
# Exit:    Returns ($platform, $language) -- both guaranteed non-empty strings.
sub _resolve_template :Protected ($self) {
	my $conf         = $self->app->config;
	my $cfg_platform = $conf->{platform} // 'web';
	my $cfg_language = $conf->{language} // 'en';

	# Detect platform from the request User-Agent via CGI::Info.
	# Falls back to the configured platform when:
	#   (a) CGI::Info is unavailable or throws, or
	#   (b) no templates/<detected>/ directory exists.
	my $platform = _detect_platform(
		$self->req->headers->user_agent // '',
		$cfg_platform,
	);
	unless (-d $self->app->home->child("templates/$platform")) {
		$platform = $cfg_platform;
	}

	my $language = $self->_resolve_language($platform, $cfg_language);
	return ($platform, $language);
}

# _detect_platform($user_agent, $fallback) -> $platform_string
#
# Purpose: Map a raw User-Agent string to a VWF platform dimension
#          ('mobile', 'tablet', or 'web') via CGI::Info.
# Entry:   $user_agent -- the raw HTTP User-Agent header value (may be empty).
#          $fallback   -- value to return if detection fails.
# Exit:    Returns 'mobile', 'tablet', 'web', or $fallback.
# Side Effects: temporarily sets $ENV{HTTP_USER_AGENT} with local().
sub _detect_platform ($user_agent, $fallback) {
	my $platform = eval {
		local $ENV{HTTP_USER_AGENT} = $user_agent;
		my $info = CGI::Info->new();
		$info->is_mobile() ? 'mobile'
		: $info->is_tablet() ? 'tablet'
		:                      'web';
	};
	return $platform // $fallback;
}

# _resolve_language($self, $platform, $default) -> $language_code
#
# Purpose: Determine the best ISO 639-1 language code for this request.
#          When Accept-Language is present, CGI::Lingua selects the best
#          match from the languages that have a template directory under
#          templates/<platform>/.  Falls back to $default when the header
#          is absent, no templates exist for the matched language, or
#          CGI::Lingua is unavailable.
# Entry:   $platform is the resolved VWF platform string.
#          $default  is a non-empty fallback language code (e.g. 'en').
# Exit:    Returns a two-letter ISO 639-1 language code string.
# Side Effects: filesystem stats for template directories;
#               temporarily sets $ENV{HTTP_ACCEPT_LANGUAGE} with local().
sub _resolve_language :Protected ($self, $platform, $default) {
	my $accept = $self->req->headers->accept_language // '';
	return $default unless $accept;

	# Discover supported languages from template directories so CGI::Lingua
	# only returns a code we can actually serve.
	my $tmpl_base = $self->app->home->child("templates/$platform");
	my @supported;
	if (-d $tmpl_base) {
		@supported = map  { Mojo::File->new($_)->basename }
		             grep { -d $_ }
		             @{ $tmpl_base->list({ dir => 1 }) };
	}
	push @supported, $default unless grep { $_ eq $default } @supported;

	my $lang = eval {
		local $ENV{HTTP_ACCEPT_LANGUAGE} = $accept;
		my $lingua = CGI::Lingua->new(supported => \@supported);
		$lingua->language_code_alpha2();
	};
	$lang //= $default;

	# Confirm a template directory exists for the chosen language.
	if ($lang ne $default) {
		my $dir = $self->app->home->child("templates/$platform/$lang");
		$lang   = $default unless -d $dir;
	}
	return $lang;
}

# _scan_data_dir($self) -> \@table_list
#
# Purpose: Return an arrayref of { name, file } hashrefs for every supported
#          data file in the configured data_dir.  Used by the index action and
#          by the join panel "available tables" dropdown.
# Entry:   None.
# Exit:    Returns [] when data_dir does not exist or contains no supported files.
# Side Effects: Filesystem directory read.
#
# Optimisation: single-pass map replaces a two-pass grep+map chain, and calls
# basename() only once per entry (the original chain called it twice: once in
# grep to check the extension and again in map to extract the stem).
# ->to_array avoids the extra flat-list expansion that ->each produced.
sub _scan_data_dir :Protected ($self) {
	my $dir = $self->app->home->child($self->app->config->{data_dir} // 'data');
	return [] unless -d $dir;
	return $dir->list->map(sub {
		my $base = $_->basename;
		return unless $base =~ $EXT_RE;
		(my $name = $base) =~ s/\.[^.]+\z//;
		{ name => $name, file => $base }
	})->to_array;
}

# _open_spec($self, $spec) -> ($DataSource, $label) or ()
#
# Purpose: Parse a "table:name" or "path:/abs/path" spec, verify the underlying
#          file exists (Database::Abstraction creates empty objects silently for
#          missing files, so we must check ourselves), and return a live
#          DataSource object and a display label.
# Entry:   $spec is a non-empty string.
# Exit:    Returns ($datasource, $label) on success; an empty list on any failure
#          (invalid spec format, file missing, DataSource init error).
# Side Effects: Filesystem stat; DataSource construction (reads file header).
sub _open_spec :Protected ($self, $spec) {
	if ($spec =~ /\Atable:([A-Za-z0-9_]+)\z/) {
		my $table    = lc $1;
		my $data_dir = $self->app->home->child($self->app->config->{data_dir} // 'data');
		return () unless grep { -f $data_dir->child("$table.$_") } @SUPPORTED_EXT;
		my $src = eval { $self->open_table($table, directory => $data_dir->to_string) };
		return ($src, $table) if $src && !$@;
	}
	elsif ($spec =~ /\Apath:(.+)\z/) {
		my $file = eval { Mojo::File->new($1)->realpath };
		if (defined $file && -f $file && $file->basename =~ $EXT_RE) {
			my $dir = $file->dirname->to_string;
			(my $table = $file->basename) =~ s/\.[^.]+\z//;
			my $src = eval { $self->open_table($table, directory => $dir) };
			return ($src, $file->basename) if $src && !$@;
		}
	}
	elsif ($spec =~ $URL_SPEC_RE) {
		my $url = $1;
		return () unless _is_safe_url($url);
		my $src = eval { $self->open_table('', url => $url) };
		return ($src, $src->table_name) if $src && !$@;
	}
	return ();
}

# _spec_to_url($self, $spec) -> $url_string
#
# Purpose: Convert a table/path spec back to a browseable URL (used for the
#          back-link on join and export views).
# Entry:   $spec is a "table:name" or "path:/abs" string.
# Exit:    Returns a URL string beginning with '/'.
sub _spec_to_url :Protected ($self, $spec) {
	return "/view/$1"                         if $spec =~ /\Atable:([A-Za-z0-9_]+)\z/;
	return '/open?path=' . url_escape($1)     if $spec =~ /\Apath:(.+)\z/;
	return '/import?url=' . url_escape($1)    if $spec =~ $URL_SPEC_RE;
	return '/';
}

# _get_columns($source, $records) -> @column_names
#
# Purpose: Return an ordered column list from a DataSource object.
#          For CSV/PSV the DataSource stores the original file-header order.
#          For SQLite/XML where no file-header order is available, the fallback
#          is: id_column first (only if it actually appears in the data), then
#          the remaining columns sorted alphabetically.
# Entry:   $source is a DataSource; $records is an arrayref of hashrefs (may be empty).
# Exit:    Returns a flat list of column-name strings (may be empty).
#
# Reduction: columns() is a pure accessor -- cache once to avoid a redundant
# method dispatch on the second reference.
sub _get_columns {
	my ($source, $records) = @_;
	my $cols = $source->columns;
	return @$cols if $cols;
	return () unless $records->[0];
	my %all = map { $_ => 1 } keys %{ $records->[0] };
	my $c   = $source->id_column;
	my $id  = ($c && $all{$c}) ? $c : (sort keys %all)[0];
	delete $all{$id};
	return ($id, sort keys %all);
}

# _apply_filter_spec($records, $spec) -> \@filtered_records
#
# Purpose: Apply one "col:op:val" filter to an arrayref of record hashrefs and
#          return a new (possibly shorter) arrayref.  The original is not mutated.
#          Value may contain colons: "col:op:val:with:colons" -- split limit 3
#          puts everything after the second colon into $val.
#          Unknown operators fall through to 1 (all rows pass) so new operators
#          added in future do not break existing callers.
# Entry:   $records is an arrayref of hashrefs; $spec is a colon-delimited string.
# Exit:    Returns filtered arrayref (same reference if spec is invalid/unparseable).
#
# Domain Constraints (operator names):
#   Operator names are CASE-SENSITIVE.  Only the exact lowercase forms below are
#   recognised; an uppercase or mixed-case name (e.g. "EQ", "Lt") falls through
#   to the default `1` branch and all rows pass unfiltered.
#   Valid operators:
#     String (value comparison is case-insensitive via lc()):
#       eq, ne, contains, starts
#     Numeric (Perl <, <=, >, >= coercion):
#       lt (strict), le (inclusive), gt (strict), ge (inclusive)
#     Unary (val is ignored):
#       empty (cell eq ''), notempty (cell ne '')
#   Boundary rules for numeric operators:
#     le/ge include the boundary value; lt/gt exclude it.
#   contains/starts with empty val ('') match every record (index always 0).
#
# Reduction: split(/:/, $spec, 3) always produces at least one defined element,
# so "defined $col" is structurally guaranteed true and is removed.
# "$_->{$col} // ''" replaces the equivalent ternary form.
#
# Optimisation: $lval = lc($val) is computed once before the grep.  Without this
# precompute, every case-insensitive operator (eq, ne, contains, starts) would
# call lc($val) O(N) times for N records -- a pure O(N) waste since $val is
# constant within a single filter application.
sub _apply_filter_spec {
	my ($records, $spec) = @_;
	my ($col, $op, $val) = split /:/, $spec, 3;
	return $records unless length($col // '') && defined $op && length $op;
	$val //= '';
	my $lval = lc $val;	# precompute once; avoids O(N) redundant lc() inside grep
	return [grep {
		my $cell = $_->{$col} // '';
		$op eq 'eq'       ? lc($cell) eq $lval                :
		$op eq 'ne'       ? lc($cell) ne $lval                :
		$op eq 'contains' ? index(lc($cell), $lval) != -1     :
		$op eq 'starts'   ? index(lc($cell), $lval) == 0      :
		$op eq 'lt'       ? $cell <  $val                     :
		$op eq 'le'       ? $cell <= $val                     :
		$op eq 'gt'       ? $cell >  $val                     :
		$op eq 'ge'       ? $cell >= $val                     :
		$op eq 'empty'    ? $cell eq ''                        :
		$op eq 'notempty' ? $cell ne ''                        :
		1
	} @$records];
}

# _apply_filters($self, $records) -> ($filtered_records, \@raw_specs, $json_string)
#
# Purpose: Read all "f=" query params, apply them in order via _apply_filter_spec,
#          and return: the filtered arrayref, the raw spec strings (for building
#          export URLs), and a script-safe JSON string for pre-populating the UI.
# Entry:   $records is an arrayref of hashrefs.
# Exit:    Three-element list; never croaks.  $json_string has '</' escaped to
#          '<\/' so it is safe to embed directly in a <script> block.
#
# Reduction: the original code had two sequential loops over @specs -- one to
# apply filters, one to parse them for JSON.  By Modus Ponens, _apply_filter_spec
# returns $records unchanged for a malformed spec (same guard condition), so
# skipping the call for malformed specs is equivalent.  Merging into one loop
# eliminates a full O(n) pass and the redundant split() on every spec.
sub _apply_filters :Protected ($self, $records) {
	my @specs  = @{ $self->every_param('f') // [] };
	my @parsed;
	for my $s (@specs) {
		my ($col, $op, $val) = split /:/, $s, 3;
		next unless length($col // '') && defined $op && length $op;
		push @parsed, { col => $col, op => $op, val => $val // '' };
		$records = _apply_filter_spec($records, $s);
	}
	my $json = encode_json(\@parsed);
	$json =~ s{</}{<\\/}g;
	return ($records, \@specs, $json);
}

# _dedup_records(\@records, \@columns) -> \@unique_records
#
# Purpose: Remove duplicate rows from $records.  Two rows are duplicates when
#          every column value is identical (string comparison, undef treated as '').
#          Preserves the order of first occurrence.
# Entry:   $records is an arrayref of hashrefs; $columns is an arrayref of names.
# Exit:    Returns a new arrayref; the input is not modified.
sub _dedup_records {
	my ($records, $columns) = @_;
	my (%seen, @out);
	for my $row (@$records) {
		my $key = join "\x00", map { $row->{$_} // '' } @$columns;
		push @out, $row unless $seen{$key}++;
	}
	return \@out;
}

# _left_join($left_recs, $left_cols, $left_key,
#            $right_recs, $right_cols, $right_key, $right_label)
#   -> (\@merged_records, \@merged_columns)
#
# Purpose: Perform a single in-memory left join.  Every left row is kept.
#          Right-table columns are appended for rows that match on the join key.
#          Unmatched rows receive undef for right-table columns.
#          If a right column name collides with a left column (other than the
#          join key itself), the right column is prefixed with "$right_label.".
# Entry:   All arrayref args non-undef; key strings non-empty; $right_label is
#          a display label used for collision-prefix (not for SQL quoting).
# Exit:    Returns (\@merged, \@column_list).
# Side Effects: None; allocates new record hashrefs.
sub _left_join {
	my ($left_recs, $left_cols, $left_key,
	    $right_recs, $right_cols, $right_key, $right_label) = @_;

	# Build a lookup hash from join key to first matching right row.
	my %right_idx;
	for my $row (@$right_recs) {
		my $k = $row->{$right_key} // '';
		$right_idx{$k} //= $row;
	}

	# Map right column names: drop the join key (redundant), prefix collisions.
	my %left_set = map { $_ => 1 } @$left_cols;
	my (@add_cols, %col_map);
	for my $col (grep { $_ ne $right_key } @$right_cols) {
		my $out = $left_set{$col} ? "${right_label}.${col}" : $col;
		$col_map{$col} = $out;
		push @add_cols, $out;
	}

	# Precompute [$right_col, $mapped_col] pairs once before the merge loop.
	# Without this, "grep { $_ ne $right_key } @$right_cols" would run on
	# every left row -- O(N_left * R) grep iterations for R right columns.
	# Precomputing reduces that to a single O(R) pass.
	my @rcols = map { [$_, $col_map{$_}] }
	            grep { $_ ne $right_key } @$right_cols;

	my @merged;
	for my $left_row (@$left_recs) {
		my $k         = $left_row->{$left_key} // '';
		my $right_row = $right_idx{$k} // {};
		my %row       = %$left_row;
		$row{ $_->[1] } = $right_row->{ $_->[0] } for @rcols;
		push @merged, \%row;
	}

	return (\@merged, [@$left_cols, @add_cols]);
}

# _combine_tables(\@sources) -> (\@merged_records, \@merged_columns)
#
# Purpose: Perform a vertical stack (UNION ALL equivalent) of two or more
#          record sets.  The merged column list is the union of all source
#          column lists: the first source's columns appear first (in their
#          original order), then each subsequent source contributes any new
#          column names it introduces, in order.  Where a source does not
#          have a particular column, its rows receive an empty string for
#          that column.
# Entry:   $sources is an arrayref of [$records_aref, $columns_aref] pairs.
#          At least one element is required; a single-element call returns
#          that element's data unchanged (no allocation beyond the column copy).
# Exit:    Returns (\@merged_records, \@merged_columns).
# Side Effects: None; allocates new record hashrefs (original rows are not mutated).
sub _combine_tables {
	my ($sources) = @_;

	# Build the unified column order: first source's columns first, then any
	# new columns introduced by each subsequent source in their file order.
	my (@all_cols, %seen);
	for my $src (@$sources) {
		for my $col (@{ $src->[1] }) {
			push @all_cols, $col unless $seen{$col}++;
		}
	}

	my @merged;
	for my $src (@$sources) {
		my ($recs, $cols) = @$src;
		my %has_col = map { $_ => 1 } @$cols;
		for my $row (@$recs) {
			my %new_row;
			$new_row{$_} = $has_col{$_} ? ($row->{$_} // '') : ''
				for @all_cols;
			push @merged, \%new_row;
		}
	}

	return (\@merged, \@all_cols);
}

# _csv_row(@fields) -> $csv_line_with_crlf
#
# Purpose: Format one row as an RFC 4180 CSV line.  Fields containing commas,
#          double-quotes, or newlines are enclosed in double-quotes; embedded
#          double-quotes are doubled.  The line ends with CRLF.
# Entry:   @fields may contain undef (treated as empty string).
# Exit:    Returns a string ending with "\r\n".
sub _csv_row {
	return join(',', map {
		my $f = $_ // '';
		$f =~ /[,"\r\n]/ ? do { (my $q = $f) =~ s/"/""/g; qq{"$q"} } : $f;
	} @_) . "\r\n";
}

# _build_export_url($self, $left_spec, \@join_specs, \@filter_specs) -> $url_string
#
# Purpose: Assemble a /export?l=...&j=...&f=... URL string for the current
#          logical view.  The caller must apply | html in TT to escape & as &amp;.
# Entry:   All args non-undef; spec arrays may be empty.
# Exit:    Returns a relative URL string beginning with '/export'.
sub _build_export_url :Protected ($self, $left_spec, $join_specs, $filter_specs, $combine_specs = undef, $dedup = 0) {
	my $u = '/export?l=' . url_escape($left_spec);
	$u .= '&j=' . url_escape($_) for @$join_specs;
	$u .= '&c=' . url_escape($_) for @{ $combine_specs // [] };
	$u .= '&f=' . url_escape($_) for @$filter_specs;
	$u .= '&d=1' if $dedup;
	return $u;
}

# _list_dir($self, $dir, $want_files) -> { dirs => [...], files => [...] }
#
# Purpose: Shared directory-listing kernel used by browse (which needs files)
#          and dirs_api (which needs only subdirectories).  Hidden entries
#          (names starting with ".") are excluded.  Entries are sorted
#          case-insensitively.
# Entry:   $dir is a Mojo::File pointing to an existing readable directory.
#          $want_files: if true, populate 'files' with entries matching $EXT_RE.
# Exit:    Returns a hashref with 'dirs' and 'files' arrayrefs (files is always
#          present but empty when $want_files is false).
# Side Effects: Filesystem directory read.
sub _list_dir :Protected ($self, $dir, $want_files) {
	my (@dirs, @files);
	if (opendir my $dh, $dir->to_string) {
		while (my $entry = readdir $dh) {
			next if $entry eq '.' || $entry eq '..' || $entry =~ /\A\./;
			my $f = $dir->child($entry);
			if (-d $f) {
				push @dirs,  { name => $entry, path => $f->to_string };
			}
			elsif ($want_files && $entry =~ $EXT_RE) {
				push @files, { name => $entry, path => $f->to_string };
			}
		}
		closedir $dh;
	}
	return {
		dirs  => [ sort { lc($a->{name}) cmp lc($b->{name}) } @dirs  ],
		files => [ sort { lc($a->{name}) cmp lc($b->{name}) } @files ],
	};
}

# _write_sqlite_db($self, $records, $columns) -> $raw_bytes
#
# Purpose: Write $records to an in-process SQLite database (single table named
#          "data"; every column declared TEXT) and return the raw file bytes.
#          The temporary file is created, written, read, and then unlinked in
#          one synchronous sequence.  Used by both _render_sqlite (HTTP download)
#          and export_write (filesystem write) to eliminate code duplication.
# Entry:   $records is an arrayref of hashrefs; $columns is an arrayref of names.
# Exit:    Returns scalar binary string.  Croaks on any DBI error.
# Side Effects: Creates and unlinks one temporary file under system tmpdir.
sub _write_sqlite_db :Protected ($self, $records, $columns) {
	# D~ fix: an empty column list produces "CREATE TABLE data ()" which is
	# invalid SQLite syntax.  Croak before touching the filesystem.
	croak 'Cannot export SQLite: result set has no columns'
		unless @$columns;

	require DBI;
	my ($tmp_fh, $tmpfile) = tempfile(SUFFIX => '.db', UNLINK => 0);
	close $tmp_fh;

	my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$tmpfile", '', '', {
		RaiseError => 1, AutoCommit => 1,
	}) };
	# Guard both the eval-caught die ($@) and the undef-without-die edge case.
	if ($@ || !$dbh) {
		unlink $tmpfile;
		croak "DBI connect failed: $@";
	}

	# O~ fix: wrap all DBI work in eval so any mid-flight exception still
	# triggers cleanup (disconnect + unlink) before the error propagates.
	eval {
		my @quoted = map { (my $c = $_) =~ s/"/""/g; qq{"$c"} } @$columns;
		$dbh->do('CREATE TABLE "data" (' . join(', ', map { "$_ TEXT" } @quoted) . ')');
		if (@$records) {
			my $ph  = join(', ', ('?') x scalar @$columns);
			my $sth = $dbh->prepare(
				'INSERT INTO "data" (' . join(', ', @quoted) . ") VALUES ($ph)"
			);
			for my $row (@$records) {
				$sth->execute(map { $row->{$_} } @$columns);
			}
		}
		$dbh->disconnect;
	};
	if (my $err = $@) {
		eval { $dbh->disconnect };	# best-effort; may already be disconnected
		unlink $tmpfile;
		croak $err;
	}

	my $data = Mojo::File->new($tmpfile)->slurp;
	unlink $tmpfile;
	return $data;
}

# _run_export_pipeline($self) -> ($records, \@columns, $left_label) or ()
#
# Purpose: Shared join+filter pipeline executed by both export_data (GET, download)
#          and export_write (POST, filesystem write).  Opens the left table, applies
#          all join steps, then applies all filter specs.
# Entry:   Reads "l=", "j=" (repeatable), and "f=" (repeatable) query/body params.
# Exit:    On success: ($filtered_arrayref, \@column_names, $left_label_string).
#          On failure: empty list (left table not found / fetch error).
# Side Effects: Opens data files; may emit carp warnings for empty result sets.
sub _run_export_pipeline :Protected ($self) {
	my $left_spec = $self->param('l') // '';
	my ($left_src, $left_label) = $self->_open_spec($left_spec);
	return () unless $left_src;

	my $left_recs = eval { $left_src->fetch_all };
	return () if $@;
	$left_recs //= [];

	my @columns = _get_columns($left_src, $left_recs);
	my $records  = $left_recs;

	for my $jspec (@{ $self->every_param('j') }) {
		my ($right_spec, $left_key, $right_key) = split /\|/, $jspec, 3;
		next unless defined $right_spec && defined $left_key && defined $right_key;
		my %col_set = map { $_ => 1 } @columns;
		next unless $col_set{$left_key};
		my ($right_src, $right_label) = $self->_open_spec($right_spec);
		next unless $right_src;
		my $right_recs = eval { $right_src->fetch_all } // [];
		next if $@;
		my @right_cols = _get_columns($right_src, $right_recs);
		my %right_set  = map { $_ => 1 } @right_cols;
		next unless $right_set{$right_key};
		($records, my $new_cols) = _left_join(
			$records, \@columns, $left_key,
			$right_recs, \@right_cols, $right_key, $right_label,
		);
		@columns = @$new_cols;
	}

	# Combine (vertical stack) with any c= sources.  Runs after joins so a join
	# result can itself be stacked with another table in a single pipeline.
	my @cspecs = @{ $self->every_param('c') // [] };
	if (@cspecs) {
		my @sources = ([$records, \@columns]);
		for my $cspec (@cspecs) {
			my ($csrc) = $self->_open_spec($cspec);
			next unless $csrc;
			my $crecs = eval { $csrc->fetch_all } // [];
			next if $@;
			my @ccols = _get_columns($csrc, $crecs);
			push @sources, [$crecs, \@ccols];
		}
		if (@sources > 1) {
			($records, my $new_cols) = _combine_tables(\@sources);
			@columns = @$new_cols;
		}
	}

	for my $s (@{ $self->every_param('f') }) {
		$records = _apply_filter_spec($records, $s);
	}

	$records = _dedup_records($records, \@columns) if $self->param('d');

	return ($records, \@columns, $left_label);
}

# _serialize_csv($records, \@columns) -> $utf8_string
#
# Purpose: Build a complete RFC 4180 CSV document (header + data rows) from
#          $records.  Shared by _render_csv (HTTP download) and the csv branch
#          of export_write (filesystem write) to eliminate duplicated logic.
# Entry:   $records is an arrayref of hashrefs; $columns is an arrayref of names.
# Exit:    Returns a UTF-8 Perl string ending with CRLF.
#
# Optimisation: rows are collected in @lines and joined in one operation.
# The previous pattern ($out .= _csv_row(...) per row) triggers O(N) string
# reallocations; joining a pre-built array is a single O(total_bytes) allocation.
# For exports of thousands of rows the difference is measurable.
#
# XS note: for very large exports, replacing _csv_row with Text::CSV_XS
# (available from CPAN) would further reduce serialisation time -- its C-level
# implementation is roughly 5-10x faster than the pure-Perl version here.
sub _serialize_csv {
	my ($records, $columns) = @_;
	my @lines = _csv_row(@$columns);
	for my $row (@$records) {
		push @lines, _csv_row(map { $row->{$_} } @$columns);
	}
	return encode('UTF-8', join('', @lines));
}

# _render_csv($self, $records, \@columns, $name) -> void (renders response)
#
# Purpose: Serialise $records to RFC 4180 CSV and emit as a UTF-8 download.
# Entry:   $name is a safe filename stem (alphanumeric/underscore).
# Exit:    Renders the Mojolicious response; does not return a meaningful value.
# Side Effects: Writes HTTP response headers and body.
sub _render_csv :Protected ($self, $records, $columns, $name) {
	$self->res->headers->content_type('text/csv; charset=UTF-8');
	$self->res->headers->content_disposition(qq{attachment; filename="${name}.csv"});
	$self->render(data => _serialize_csv($records, $columns));
}

# _render_sqlite($self, $records, \@columns, $name) -> void (renders response)
#
# Purpose: Write $records to a SQLite database and emit it as a binary download.
# Entry:   $name is a safe filename stem.
# Exit:    Renders the Mojolicious response.
# Side Effects: Creates and unlinks a temporary file; writes HTTP response.
sub _render_sqlite :Protected ($self, $records, $columns, $name) {
	my $data = $self->_write_sqlite_db($records, $columns);
	$self->res->headers->content_type('application/vnd.sqlite3');
	$self->res->headers->content_disposition(qq{attachment; filename="${name}.db"});
	$self->render(data => $data);
}

# _render_json($self, $records, \@columns, $name) -> void (renders response)
#
# Purpose: Emit $records as a JSON array download.
# Entry:   $records is an arrayref of hashrefs; $name is a safe filename stem.
# Exit:    Renders the Mojolicious response.
# Side Effects: Writes HTTP response headers and body.
sub _render_json :Protected ($self, $records, $columns, $name) {
	$self->res->headers->content_disposition(qq{attachment; filename="${name}.json"});
	$self->render(json => $records);
}

# ---------------------------------------------------------------------------
# Public actions
# ---------------------------------------------------------------------------

=head1 ACTIONS

=head2 index

C<GET /> -- Scan C<data_dir> and present a card grid of available tables.

=head3 API SPECIFICATION

=head4 INPUT

None (reads C<data_dir> from application config).

=head4 OUTPUT

Renders C<home.html.tt> with:

  tables     ARRAYREF of { name => $stem, file => $basename }
  title      'Choose a Database'

=head3 MESSAGES

None produced by this action; any file-scan errors are silently ignored
(empty directory yields an empty card grid).

=head3 FORMAL SPECIFICATION

  index == lambda self .
    let dir  = resolve self.app.config.data_dir in
    let tbls = { b | b in dir /\ basename(b) =~ EXT_RE } in
    post render(home, tables: map(stem, tbls))

=head3 EXAMPLE

  GET / -> 200 text/html containing a card for each file in data/

=cut

sub index ($self) {
	my ($platform, $language) = $self->_resolve_template;

	$self->render(
		template => "$platform/$language/home",
		handler  => 'tt',
		format   => 'html',
		tables   => $self->_scan_data_dir,
		title    => 'Choose a Database',
	);
}

=head2 view

C<GET /view/:table> -- Open and display the chosen table from C<data_dir>.

=head3 API SPECIFICATION

=head4 INPUT

  :table   string   Table name (alphanumeric + underscore).  Returns 404 on
                    other characters.
  ?f=      string   (repeatable) Filter spec: "col:op:val".

=head4 DOMAIN CONSTRAINTS: :table

C<:table> is validated against C<\A[A-Za-z_][A-Za-z0-9_]*\z> before C<open_table>
is ever called.  The first character must be a letter (A-Z, a-z) or an
underscore; subsequent characters may also include digits (0-9).

=over 4

=item Valid partition

C<sales> (letters only), C<_temp> (underscore-start), C<report_2024>
(mixed).  A name that is valid but has no backing file returns 200 with
an error message -- NOT 404.

=item Invalid partition

C<1sales> (digit-start, 404), C<my.data> (dot, 404), C<my-data>
(hyphen, 404), non-ASCII characters (404).

=item Boundary values

C<a> (single letter, valid), C<_> (single underscore, valid), C<1>
(single digit, 404), C<a1> (letter then digit, valid), C<1a> (digit
then letter, 404).

=back

=head4 OUTPUT

On success renders C<dashboard.html.tt> with table data.
On error re-renders C<home.html.tt> with an C<error> stash variable.

=head3 MESSAGES

  error_table_open   -- DataSource initialisation or fetch_all threw.

=head3 FORMAL SPECIFICATION

  view == lambda self .
    pre  self.stash('table') =~ TABLE_NAME_RE
    let src     = open_table(table) in
    let records = src.fetch_all()   in
    let cols    = get_columns(src, records) in
    post render(dashboard, records: filter(records, f_params))

=head3 EXAMPLE

  GET /view/sales      -> 200 HTML table of all sales rows
  GET /view/sales?f=region:eq:North -> shows only North region rows
  GET /view/../etc     -> 404

=cut

sub view ($self) {
	my ($platform, $language) = $self->_resolve_template;
	my $table = $self->stash('table');

	unless (defined $table && $table =~ $TABLE_NAME_RE) {
		return $self->reply->not_found;
	}

	my ($source, $records);
	eval { $source = $self->open_table($table); $records = $source->fetch_all };
	if ($@) {
		return $self->render(
			template => "$platform/$language/home",
			handler  => 'tt',
			format   => 'html',
			tables   => [],
			title    => 'Choose a Database',
			error    => $self->_i18n('error_table_open', $table, $@),
		);
	}

	my @columns = _get_columns($source, $records);
	my ($filtered, $filter_specs, $filters_json) = $self->_apply_filters($records);
	my $dedup = $self->param('d') ? 1 : 0;
	$filtered = _dedup_records($filtered, \@columns) if $dedup;

	$self->render(
		template         => "$platform/$language/dashboard",
		handler          => 'tt',
		format           => 'html',
		records          => $filtered,
		columns          => \@columns,
		table            => $table,
		title            => ucfirst($table),
		left_spec        => "table:$table",
		combine_specs    => [],
		current_joins    => [],
		available_tables => $self->_scan_data_dir,
		join_summaries   => [],
		filter_specs     => $filter_specs,
		filters_json     => $filters_json,
		dedup            => $dedup,
		export_url       => $self->_build_export_url("table:$table", [], $filter_specs, undef, $dedup),
	);
}

=head2 browse

C<GET /browse> -- Navigate the filesystem and pick a data file.

=head3 API SPECIFICATION

=head4 INPUT

  ?path=   string   Absolute filesystem path to browse (default: $HOME).
                    Returns 404 when the path does not exist or is not a
                    directory.

=head4 OUTPUT

Renders C<browse.html.tt> with:

  current_path   string
  parent_href    string or undef (undef at filesystem root)
  crumbs         ARRAYREF of { name, href }
  dirs           ARRAYREF of { name, href }   -- subdirectories, sorted
  files          ARRAYREF of { name, href }   -- supported data files, sorted

=head3 MESSAGES

None; errors render as 404.

=head3 FORMAL SPECIFICATION

  browse == lambda self .
    let dir = realpath(param('path') // HOME) in
    pre  is_dir(dir)
    post render(browse, dirs: subdirs(dir), files: supported_files(dir))

=head3 EXAMPLE

  GET /browse                            -> 200, lists $HOME
  GET /browse?path=/tmp                  -> 200, lists /tmp
  GET /browse?path=/nonexistent/xyz      -> 404

=cut

sub browse ($self) {
	my ($platform, $language) = $self->_resolve_template;

	my $raw_path = $self->param('path') // $ENV{HOME} // '/';
	my $dir      = eval { Mojo::File->new($raw_path)->realpath };
	return $self->reply->not_found unless defined $dir && -d $dir;

	my $listing = $self->_list_dir($dir, 1);

	# Add browse hrefs to file entries (dirs already have path; browse needs href).
	my @dirs = map {
		+{ name => $_->{name}, href => '/browse?path=' . url_escape($_->{path}) }
	} @{ $listing->{dirs} };

	my @files = map {
		+{ name => $_->{name}, href => '/open?path=' . url_escape($_->{path}) }
	} @{ $listing->{files} };

	# Build breadcrumb trail from filesystem root down to $dir.
	my @crumbs;
	{
		my $f = $dir;
		while (1) {
			my $name = $f->basename;
			$name    = '/' unless length $name;
			unshift @crumbs, { name => $name, href => '/browse?path=' . url_escape($f->to_string) };
			my $parent = $f->dirname;
			last if $parent->to_string eq $f->to_string;
			$f = $parent;
		}
	}

	my $parent      = $dir->dirname;
	my $parent_href = $parent->to_string ne $dir->to_string
		? '/browse?path=' . url_escape($parent->to_string)
		: undef;

	$self->render(
		template     => "$platform/$language/browse",
		handler      => 'tt',
		format       => 'html',
		title        => 'Browse Files',
		current_path => $dir->to_string,
		parent_href  => $parent_href,
		crumbs       => \@crumbs,
		dirs         => \@dirs,
		files        => \@files,
	);
}

=head2 open_file

C<GET /open> -- Open a supported data file from any absolute filesystem path.

=head3 API SPECIFICATION

=head4 INPUT

  ?path=   string   Absolute path to the data file.  Returns 404 when missing,
                    not a regular file, or the extension is not in SUPPORTED_EXT.
  ?f=      string   (repeatable) Filter spec: "col:op:val".

=head4 DOMAIN CONSTRAINTS: ?path=

=over 4

=item Extension filter (C<EXT_RE>)

The basename must match C<\.(?:csv|db|sql|xml|psv)\z> (case-insensitive).
The C<\z> anchor (absolute end-of-string) means a URL-encoded trailing
newline (e.g. C<file.csv%0A> decoded to C<file.csv\n>) does NOT pass --
the C<\n> falls after the C<\z> boundary and the extension check fails.

=item Valid partition

C</data/sales.csv> (lowercase extension), C</tmp/REPORT.CSV> (uppercase
extension, /i matches), any C<.db>, C<.sql>, C<.xml>, C<.psv> regular
file.

=item Invalid partition

Absent C<?path=> (404), non-existent file (404), directory instead of
file (404), unsupported extension such as C<.txt> (404), empty string
(404), path containing a C<%0A> (newline) suffix (404).

=item Double-extension filenames

A file like C<file.php.csv> passes C<EXT_RE> (last segment is C<.csv>)
but produces table stem C<file.php> which fails C<DataSource>'s
C<TABLE_NAME_RE>.  The C<open_table> call is inside C<eval>, so the
croak is caught and the action returns 200 with a friendly error, not
a 500.

=back

=head4 OUTPUT

On success renders C<dashboard.html.tt> with C<back_url> pointing to the
directory's C</browse> page, and C<file_path> set to the resolved absolute
path (used by the template to record the file in C<localStorage>).
On error re-renders C<home.html.tt> with C<error>, C<back_url>, C<back_label>.

=head3 MESSAGES

  error_file_open   -- DataSource threw during initialisation or fetch_all.

=head3 FORMAL SPECIFICATION

  open_file == lambda self .
    let file = realpath(param('path')) in
    pre  is_file(file) /\ basename(file) =~ EXT_RE
    let src = open_table(stem(file), dir=dirname(file)) in
    post render(dashboard, file_path: file.to_string)

=head3 EXAMPLE

  GET /open?path=/data/archive/sales.csv   -> 200, table view
  GET /open                                -> 404
  GET /open?path=/etc/passwd               -> 404

=cut

sub open_file ($self) {
	my ($platform, $language) = $self->_resolve_template;
	my $file_path = $self->param('path');

	return $self->reply->not_found unless defined $file_path;

	my $file = eval { Mojo::File->new($file_path)->realpath };
	return $self->reply->not_found
		unless defined $file && -f $file && $file->basename =~ $EXT_RE;

	my $dir      = $file->dirname;
	(my $table   = $file->basename) =~ s/\.[^.]+\z//;
	my $back     = '/browse?path=' . url_escape($dir->to_string);
	my $filename = $file->basename;
	my $lspec    = 'path:' . $file->to_string;

	my ($source, $records);
	eval { $source = $self->open_table($table, directory => $dir->to_string); $records = $source->fetch_all };
	if ($@) {
		return $self->render(
			template   => "$platform/$language/home",
			handler    => 'tt',
			format     => 'html',
			tables     => [],
			title      => 'Error',
			error      => $self->_i18n('error_file_open', $filename, $@),
			back_url   => $back,
			back_label => 'Back to browser',
		);
	}

	my @columns  = _get_columns($source, $records);
	my ($filtered, $filter_specs, $filters_json) = $self->_apply_filters($records);
	my $dedup = $self->param('d') ? 1 : 0;
	$filtered = _dedup_records($filtered, \@columns) if $dedup;

	$self->render(
		template         => "$platform/$language/dashboard",
		handler          => 'tt',
		format           => 'html',
		records          => $filtered,
		columns          => \@columns,
		table            => $table,
		title            => $filename,
		back_url         => $back,
		back_label       => 'Back to browser',
		file_path        => $file->to_string,
		left_spec        => $lspec,
		combine_specs    => [],
		current_joins    => [],
		available_tables => $self->_scan_data_dir,
		join_summaries   => [],
		filter_specs     => $filter_specs,
		filters_json     => $filters_json,
		dedup            => $dedup,
		export_url       => $self->_build_export_url($lspec, [], $filter_specs, undef, $dedup),
	);
}

=head2 import_url

C<GET /import> -- Fetch a remote HTML page, extract the first (or selected)
table, and render it as a sortable data grid.

=head3 API SPECIFICATION

=head4 INPUT

  ?url=          string   Required.  Full http:// or https:// URL of the page
                          that contains the HTML table.  Returns home with an
                          error message if the scheme is wrong, the fetch fails,
                          or no table is found at the specified index.
  ?table_index=  integer  Zero-based index of the C<< <table> >> to use when
                          the page contains more than one table (default: 0).
  ?f=            string   (repeatable) Filter spec: "col:op:val".

=head4 OUTPUT

On success renders C<dashboard.html.tt> with the same stash shape as C<open_file>,
plus C<source_url> (the original URL) for C<localStorage> tracking.

On error re-renders C<home.html.tt> with an C<error> stash variable.

=head3 MESSAGES

  error_url_required  -- empty or missing C<url> param
  error_url_invalid   -- URL does not begin with http:// or https://
  error_url_fetch     -- LWP fetch failure or no table found at the index

=head3 EXAMPLE

  GET /import?url=https://matrix.perl-magpie.org/dist/Database-Abstraction/
  GET /import?url=https://example.com/data.html&table_index=2

=cut

sub import_url ($self) {
	my ($platform, $language) = $self->_resolve_template;

	my $url = $self->param('url') // '';
	my $idx = $self->param('table_index') // 0;
	$idx    = 0 unless $idx =~ /\A[0-9]+\z/;

	my $err_home = sub ($key, @args) {
		$self->render(
			template => "$platform/$language/home",
			handler  => 'tt',
			format   => 'html',
			tables   => $self->_scan_data_dir,
			title    => 'Choose a Database',
			error    => $self->_i18n($key, @args),
		);
	};

	return $err_home->('error_url_required') unless length $url;
	return $err_home->('error_url_invalid', $url)
		unless $url =~ m{\Ahttps?://}i;
	return $err_home->('error_url_ssrf', $url)
		unless _is_safe_url($url);

	my $source = eval { $self->open_table('', url => $url, html_table_index => $idx) };
	return $err_home->('error_url_fetch', $url, $@ // 'unknown error') if $@ || !$source;

	my $records = eval { $source->fetch_all };
	return $err_home->('error_url_fetch', $url, $@ // 'empty result') if $@;

	my $label   = $source->table_name;
	my $lspec   = "url:$url";
	my @columns = _get_columns($source, $records);
	my ($filtered, $filter_specs, $filters_json) = $self->_apply_filters($records);
	my $dedup = $self->param('d') ? 1 : 0;
	$filtered = _dedup_records($filtered, \@columns) if $dedup;

	$self->render(
		template         => "$platform/$language/dashboard",
		handler          => 'tt',
		format           => 'html',
		records          => $filtered,
		columns          => \@columns,
		table            => $label,
		title            => $label,
		source_url       => $url,
		back_url         => '/',
		back_label       => 'Choose another database',
		left_spec        => $lspec,
		combine_specs    => [],
		current_joins    => [],
		available_tables => $self->_scan_data_dir,
		join_summaries   => [],
		filter_specs     => $filter_specs,
		filters_json     => $filters_json,
		dedup            => $dedup,
		export_url       => $self->_build_export_url($lspec, [], $filter_specs, undef, $dedup),
	);
}

=head2 columns_api

C<GET /api/columns> -- Return column names for a table or file as JSON.

Used by the join UI to populate the right-key dropdown without a page reload.

=head3 API SPECIFICATION

=head4 INPUT

  ?table=  string   Table name from C<data_dir>.
  ?path=   string   Absolute path to a data file.
  ?spec=   string   Unified spec: C<"table:name"> or C<"path:/abs/path">.
                    Parsed only when C<table> and C<path> are both absent.

One of C<table>, C<path>, or C<spec> must be present; C<table> takes
precedence over C<path>, and both take precedence over C<spec>.

=head4 OUTPUT

  200 application/json   { "columns": ["col1", "col2", ...] }
  404 application/json   { "error": "not found" }

=head3 MESSAGES

None produced by this action directly; internal errors yield a 404.

=head3 FORMAL SPECIFICATION

  columns_api == lambda self .
    let src = open_spec(table_param or path_param or parse_spec(spec_param)) in
    pre  src /= undef
    post render_json({ columns: get_columns(src) })

=head3 EXAMPLE

  GET /api/columns?table=sales            -> {"columns":["product","region","amount"]}
  GET /api/columns?spec=table:sales       -> {"columns":["product","region","amount"]}
  GET /api/columns?spec=path:/data/f.csv  -> {"columns":[...]}
  GET /api/columns?table=noexist          -> 404

=cut

sub columns_api ($self) {
	my $table_name = $self->param('table');
	my $path       = $self->param('path');

	# Accept the unified spec format used by /join and /graph:
	# "table:name" or "path:/abs/path" — mirrors _open_spec's parsing.
	if (!defined($table_name) && !defined($path)) {
		my $spec = $self->param('spec') // '';
		if ($spec =~ /\Atable:([A-Za-z_][A-Za-z0-9_]*)\z/) {
			$table_name = $1;
		} elsif ($spec =~ /\Apath:(.+)\z/s) {
			$path = $1;
		}
	}

	my $source;
	if (defined $table_name && $table_name =~ $TABLE_NAME_RE) {
		my $data_dir = $self->app->home->child($self->app->config->{data_dir} // 'data');
		return $self->render(json => { error => 'not found' }, status => 404)
			unless grep { -f $data_dir->child(lc($table_name) . ".$_") } @SUPPORTED_EXT;
		$source = eval { $self->open_table(lc $table_name, directory => $data_dir->to_string) };
	}
	elsif (defined $path) {
		my $file = eval { Mojo::File->new($path)->realpath };
		if (defined $file && -f $file && $file->basename =~ $EXT_RE) {
			my $dir = $file->dirname->to_string;
			(my $tbl = $file->basename) =~ s/\.[^.]+\z//;
			$source = eval { $self->open_table($tbl, directory => $dir) };
		}
	}

	return $self->render(json => { error => 'not found' }, status => 404) unless $source;

	# Use _get_columns to ensure consistent ordering with the view action.
	my $recs = ($source->columns ? [] : eval { $source->fetch_all } // []);
	my @cols = _get_columns($source, $recs);

	$self->render(json => { columns => \@cols });
}

=head2 join_tables

C<GET /join> -- Perform one or more left joins and render the merged table.

=head3 API SPECIFICATION

=head4 INPUT

  ?l=    string   Required. Left table spec: "table:name" or "path:/abs/path".
                  Returns 404 if unresolvable.
  ?j=    string   (repeatable) Join step: "<right-spec>|<left-key>|<right-key>".
                  Invalid or non-existent steps are silently skipped.
  ?f=    string   (repeatable) Result filter: "col:op:val".

=head4 OUTPUT

Renders C<dashboard.html.tt> with the merged/filtered result set.

=head3 MESSAGES

  error_table_open   -- Left table fetch threw (re-renders home with error).

=head3 FORMAL SPECIFICATION

  join_tables == lambda self .
    let left = open_spec(param('l')) in
    pre  left /= undef
    let joined  = fold(_left_join, left, param_list('j')) in
    let filtered = fold(_apply_filter_spec, joined, param_list('f')) in
    post render(dashboard, records: filtered)

=head3 PSEUDOCODE

  1. Parse and open left table spec; 404 on failure.
  2. For each j= param (in order):
       a. Parse right-spec, left-key, right-key from "|"-split.
       b. Verify left-key exists in current column list.
       c. Open right table; skip step on any error.
       d. Verify right-key exists in right column list.
       e. Call _left_join; update records and columns.
  3. Apply all f= filters via _apply_filter_spec.
  4. Build stable table key for localStorage ("join:left:right1:...").
  5. Render dashboard.

=head3 EXAMPLE

  GET /join?l=table:sales&j=table:products|product|name
    -> merged left join of sales and products on product/name columns

=cut

sub join_tables ($self) {
	my ($platform, $language) = $self->_resolve_template;

	my $left_spec = $self->param('l') // '';
	my ($left_src, $left_label) = $self->_open_spec($left_spec);
	return $self->reply->not_found unless $left_src;

	my $left_recs = eval { $left_src->fetch_all };
	if ($@) {
		return $self->render(
			template => "$platform/$language/home",
			handler  => 'tt',
			format   => 'html',
			tables   => [],
			title    => 'Error',
			error    => $self->_i18n('error_table_open', $left_label, $@),
		);
	}
	$left_recs //= [];

	my @left_cols = _get_columns($left_src, $left_recs);
	my @join_specs = @{ $self->every_param('j') };

	my ($records, @columns, @summaries) = ($left_recs, @left_cols);

	for my $jspec (@join_specs) {
		my ($right_spec, $left_key, $right_key) = split /\|/, $jspec, 3;
		next unless defined $right_spec && defined $left_key && defined $right_key;

		# O(1) hash-set probe instead of O(C) grep for each join step.
		my %col_set = map { $_ => 1 } @columns;
		next unless $col_set{$left_key};

		my ($right_src, $right_label) = $self->_open_spec($right_spec);
		next unless $right_src;

		my $right_recs = eval { $right_src->fetch_all } // [];
		next if $@;
		my @right_cols = _get_columns($right_src, $right_recs);
		my %right_set  = map { $_ => 1 } @right_cols;
		next unless $right_set{$right_key};

		($records, my $new_cols) = _left_join(
			$records, \@columns, $left_key,
			$right_recs, \@right_cols, $right_key, $right_label,
		);
		@columns = @$new_cols;
		push @summaries, { label => $right_label, left_key => $left_key, right_key => $right_key };
	}

	my ($filtered, $filter_specs, $filters_json) = $self->_apply_filters($records);
	my $dedup = $self->param('d') ? 1 : 0;
	$filtered = _dedup_records($filtered, \@columns) if $dedup;

	my $title     = $left_label;
	$title       .= ' + ' . join(' + ', map { $_->{label} } @summaries) if @summaries;
	my $table_key = 'join:' . lc($left_label);
	$table_key   .= ':' . lc($_->{label}) for @summaries;

	$self->render(
		template         => "$platform/$language/dashboard",
		handler          => 'tt',
		format           => 'html',
		records          => $filtered,
		columns          => \@columns,
		table            => $table_key,
		title            => $title,
		back_url         => $self->_spec_to_url($left_spec),
		back_label       => "Back to $left_label",
		left_spec        => $left_spec,
		combine_specs    => [],
		current_joins    => \@join_specs,
		available_tables => $self->_scan_data_dir,
		join_summaries   => \@summaries,
		filter_specs     => $filter_specs,
		filters_json     => $filters_json,
		dedup            => $dedup,
		export_url       => $self->_build_export_url($left_spec, \@join_specs, $filter_specs, undef, $dedup),
	);
}

=head2 combine_tables

C<GET /combine> -- Stack rows from two or more tables vertically into a single
unified view.

Unlike C</join> (which appends columns from a matching row in a second table),
C</combine> appends the I<rows> from a second table beneath the rows of the
first.  All columns from all sources appear as headers; where a row has no
value for a particular column (because that column did not exist in its source
file) the cell is left blank.

This is equivalent to a SQL C<UNION ALL> across heterogeneous schemas.

=head3 API SPECIFICATION

=head4 INPUT

  ?l=    string   (required) Left table spec: "table:name" or "path:/abs/path".
                  Returns 404 if unresolvable.
  ?c=    string   (repeatable) Additional table spec to stack beneath the
                  current result.  Invalid or non-existent specs are silently
                  skipped.
  ?f=    string   (repeatable) Result filter: "col:op:val".

=head4 OUTPUT

Renders C<dashboard.html.tt> with the combined result set.

=head3 MESSAGES

  error_table_open   -- Left table fetch threw (re-renders home with error).

=head3 FORMAL SPECIFICATION

  combine_tables == lambda self .
    let left = open_spec(param('l')) in
    pre  left /= undef
    let sources  = [left] ++ map(open_spec, param_list('c')) in
    let combined = _combine_tables(sources) in
    let filtered = fold(_apply_filter_spec, combined, param_list('f')) in
    post render(dashboard, records: filtered)

=head3 EXAMPLE

  GET /combine?l=table:cats&c=table:dogs
    -> unified view: all cat and dog rows; Species/Name/Color/Breed/Eye Color
       appear for both; Environment (cats-only) and Sex/Fixed (dogs-only)
       are blank where the source file lacks that column.

=cut

sub combine_tables ($self) {
	my ($platform, $language) = $self->_resolve_template;

	my $left_spec = $self->param('l') // '';
	my ($left_src, $left_label) = $self->_open_spec($left_spec);
	return $self->reply->not_found unless $left_src;

	my $left_recs = eval { $left_src->fetch_all };
	if ($@) {
		return $self->render(
			template => "$platform/$language/home",
			handler  => 'tt',
			format   => 'html',
			tables   => [],
			title    => 'Error',
			error    => $self->_i18n('error_table_open', $left_label, $@),
		);
	}
	$left_recs //= [];

	my @left_cols     = _get_columns($left_src, $left_recs);
	my @combine_specs = @{ $self->every_param('c') };

	my @sources   = ([$left_recs, \@left_cols]);
	my @summaries;

	for my $cspec (@combine_specs) {
		my ($csrc, $clabel) = $self->_open_spec($cspec);
		next unless $csrc;
		my $crecs = eval { $csrc->fetch_all } // [];
		next if $@;
		my @ccols = _get_columns($csrc, $crecs);
		push @sources,   [$crecs, \@ccols];
		push @summaries, { label => $clabel };
	}

	my ($records, $cols_ref) = @sources > 1
		? _combine_tables(\@sources)
		: ($left_recs, \@left_cols);
	my @columns = @$cols_ref;

	my ($filtered, $filter_specs, $filters_json) = $self->_apply_filters($records);
	my $dedup = $self->param('d') ? 1 : 0;
	$filtered = _dedup_records($filtered, \@columns) if $dedup;

	my $title     = $left_label;
	$title       .= ' + ' . join(' + ', map { $_->{label} } @summaries) if @summaries;
	my $table_key = 'combine:' . lc($left_label);
	$table_key   .= ':' . lc($_->{label}) for @summaries;

	$self->render(
		template         => "$platform/$language/dashboard",
		handler          => 'tt',
		format           => 'html',
		records          => $filtered,
		columns          => \@columns,
		table            => $table_key,
		title            => $title,
		back_url         => $self->_spec_to_url($left_spec),
		back_label       => "Back to $left_label",
		left_spec        => $left_spec,
		combine_specs    => \@combine_specs,
		current_joins    => [],
		available_tables => $self->_scan_data_dir,
		join_summaries   => \@summaries,
		filter_specs     => $filter_specs,
		filters_json     => $filters_json,
		dedup            => $dedup,
		export_url       => $self->_build_export_url($left_spec, [], $filter_specs, \@combine_specs, $dedup),
	);
}

=head2 export_data

C<GET /export> -- Stream the current logical view as a browser file download.

=head3 API SPECIFICATION

=head4 INPUT

  ?l=        string   (required) Left table spec.
  ?j=        string   (repeatable) Join steps.
  ?f=        string   (repeatable) Filter specs.
  ?format=   string   "csv" (default), "sqlite", or "json".

=head4 DOMAIN CONSTRAINTS: ?format=

Exact lowercase string match.

=over 4

=item Valid partitions

C<csv> (explicit CSV), C<sqlite> (SQLite binary), C<json> (JSON array),
absent/undef (defaults to CSV).

=item Invalid partitions (all fall back to CSV)

Any value not in the valid set (e.g. C<SQLITE>, C<Json>, C<tsv>).

=back

=head4 OUTPUT

  200 text/csv                  Content-Disposition: attachment; filename=<name>.csv
  200 application/vnd.sqlite3   Content-Disposition: attachment; filename=<name>.db
  200 application/json          Content-Disposition: attachment; filename=<name>.json
  404 application/json          { "error": "Table not found" }

=head3 MESSAGES

None beyond the 404 response.

=head3 FORMAL SPECIFICATION

  export_data == lambda self .
    let (recs, cols, label) = _run_export_pipeline() in
    pre  recs /= undef
    post if format = 'sqlite' then render_sqlite(recs, cols)
         else if format = 'json' then render_json(recs, cols)
         else render_csv(recs, cols)

=head3 EXAMPLE

  GET /export?l=table:sales&format=csv     -> downloads sales.csv
  GET /export?l=table:sales&format=sqlite  -> downloads sales.db
  GET /export?l=table:sales&format=json    -> downloads sales.json

=cut

sub export_data ($self) {
	my ($records, $columns, $left_label) = $self->_run_export_pipeline;
	return $self->reply->not_found unless $records;

	my $format = $self->param('format') // 'csv';
	(my $safe_name = lc $left_label) =~ s/[^a-z0-9_]+/_/g;

	return $format eq 'sqlite' ? $self->_render_sqlite($records, $columns, $safe_name)
	     : $format eq 'json'   ? $self->_render_json($records, $columns, $safe_name)
	     :                       $self->_render_csv($records, $columns, $safe_name);
}

=head2 export_write

C<POST /export> -- Write the current logical view to a chosen filesystem path.

=head3 API SPECIFICATION

=head4 INPUT

  l=         string   (required) Left table spec.
  j=         string   (repeatable) Join steps.
  f=         string   (repeatable) Filter specs.
  dir=       string   Target directory (must exist; resolved via realpath).
  filename=  string   Output filename including extension.  Extension determines
                      format: C<.csv> -> RFC 4180 CSV; C<.sql> -> SQLite.

=head4 DOMAIN CONSTRAINTS: filename=

The extension check uses C</\.csv\z/i> (CSV) or C</\.sql\z/i> (SQLite):
the C</i> flag makes matching case-insensitive, so C<.CSV> and C<.SQL>
are accepted alongside lowercase forms.  Everything else returns 415.

Path separator characters (C</> and C<\>) in C<filename> are stripped
first via C<m{([^/\\]+)\z}> -- only the basename is kept, preventing
directory traversal.

=over 4

=item Valid partitions

C<report.csv>, C<report.sql>, C<REPORT.CSV>, C<report.SQL>.  A
single-character stem (C<a.csv>) is also valid.

=item Invalid partitions (415)

C<report.txt>, C<report.json>, C<report> (no extension), empty string.

=back

=head4 OUTPUT

  200 application/json   { "saved": "/abs/path/to/file" }
  404 application/json   { "error": "..." }  -- bad dir or table not found
  415 application/json   { "error": "..." }  -- unsupported extension
  500 application/json   { "error": "..." }  -- write failure

=head3 MESSAGES

  error_dir_not_found   -- realpath of dir failed or result is not a directory.
  error_ext_required    -- filename extension is not .csv or .sql.
  error_write_failed    -- DBI or filesystem write threw.

=head3 FORMAL SPECIFICATION

  export_write == lambda self .
    let dir  = realpath(param('dir'))      in
    let file = dir / strip_path(param('filename')) in
    pre  is_dir(dir) /\ ext(file) in {csv, sql}
    let (recs, cols, _) = _run_export_pipeline() in
    pre  recs /= undef
    post spurt(file, serialise(recs, cols))
         /\ render_json({ saved: file.to_string })

=head3 EXAMPLE

  POST /export  l=table:sales dir=/home/user/exports filename=report.csv
    -> { "saved": "/home/user/exports/report.csv" }

=cut

sub export_write ($self) {
	my $dir      = $self->param('dir')      // '';
	my $filename = $self->param('filename') // '';

	my $dest_dir = eval { Mojo::File->new($dir)->realpath };
	unless (defined $dest_dir && -d $dest_dir) {
		return $self->render(
			json   => { error => $self->_i18n('error_dir_not_found', $dir) },
			status => 404,
		);
	}

	# Strip any path separators the browser might include.
	($filename) = $filename =~ m{([^/\\]+)\z};
	my $format;
	if    ($filename && $filename =~ /\.csv\z/i)  { $format = 'csv';    }
	elsif ($filename && $filename =~ /\.sql\z/i)  { $format = 'sqlite'; }
	elsif ($filename && $filename =~ /\.json\z/i) { $format = 'json';   }
	else {
		return $self->render(
			json   => { error => $self->_i18n('error_ext_required') },
			status => 415,
		);
	}

	my ($records, $columns, $left_label) = $self->_run_export_pipeline;
	return $self->render(json => { error => 'Table not found' }, status => 404)
		unless $records;

	my $dest = $dest_dir->child($filename);
	eval {
		if ($format eq 'csv') {
			$dest->spurt(_serialize_csv($records, $columns));
		}
		elsif ($format eq 'json') {
			$dest->spurt(encode_json($records));
		}
		else {
			$dest->spurt($self->_write_sqlite_db($records, $columns));
		}
	};
	return $self->render(
		json   => { error => $self->_i18n('error_write_failed', $@) },
		status => 500,
	) if $@;

	$self->render(json => { saved => $dest->to_string });
}

=head2 dirs_api

C<GET /api/dirs> -- Return a JSON directory listing for the export panel.

=head3 API SPECIFICATION

=head4 INPUT

  ?path=   string   Directory to list (default: $HOME).  Returns 404 when not
                    a directory.  Hidden entries (names starting with ".") are
                    excluded.

=head4 OUTPUT

  200 application/json
    {
      "path":   "/abs/path",
      "parent": "/abs/parent" or null (at filesystem root),
      "dirs":   [ { "name": "alpha", "path": "/abs/path/alpha" }, ... ]
    }

  404 application/json   { "error": "Not a directory" }

=head3 MESSAGES

None beyond the 404 response.

=head3 FORMAL SPECIFICATION

  dirs_api == lambda self .
    let dir = realpath(param('path') // HOME) in
    pre  is_dir(dir)
    post render_json({ path: dir, parent: parent(dir), dirs: subdirs(dir) })

=head3 EXAMPLE

  GET /api/dirs?path=/home/user  -> {"path":"/home/user","parent":"/home","dirs":[...]}

=cut

sub dirs_api ($self) {
	my $raw = $self->param('path') // $ENV{HOME} // '/';
	my $dir = eval { Mojo::File->new($raw)->realpath };
	return $self->render(json => { error => 'Not a directory' }, status => 404)
		unless defined $dir && -d $dir;

	my $listing = $self->_list_dir($dir, 0);
	my $parent  = $dir->dirname;

	$self->render(json => {
		path   => $dir->to_string,
		parent => ($parent->to_string ne $dir->to_string ? $parent->to_string : undef),
		dirs   => $listing->{dirs},
	});
}

=head2 stat_api

C<GET /api/stat> -- Return filesystem metadata for a file path.

Used by the home page tooltip to show modification time and size for recently
opened files without a page reload.

=head3 API SPECIFICATION

=head4 INPUT

  ?path=   string   Absolute path to query.  Returns HTTP 400 when absent.

=head4 OUTPUT

  200 application/json   (file exists)
    { "exists": true, "path": "/resolved/path", "mtime": 1700000000, "size": 4096 }

  200 application/json   (file does not exist)
    { "exists": false, "path": "/original/path" }

  400 application/json   { "error": "\"path\" parameter is required" }

C<mtime> is Unix epoch seconds.  C<size> is bytes.  A missing/unresolvable
path returns HTTP 200 with C<exists: false> (not 404) so the UI can
distinguish "file was deleted" from a request error.

=head3 MESSAGES

  error_path_required   -- the "path" query parameter was not supplied.

=head3 FORMAL SPECIFICATION

  stat_api == lambda self .
    let path = param('path') in
    pre  path /= undef
    let file = realpath(path) in
    post if is_file(file) then
           render_json({ exists: true, mtime: mtime(file), size: size(file) })
         else render_json({ exists: false })

=head3 EXAMPLE

  GET /api/stat?path=/data/sales.csv
    -> { "exists": true, "path": "/data/sales.csv", "mtime": 1700000000, "size": 1234 }

  GET /api/stat?path=/deleted.csv
    -> { "exists": false, "path": "/deleted.csv" }

=cut

sub stat_api ($self) {
	my $path = $self->param('path');
	unless (defined $path && length $path) {
		return $self->render(
			json   => { error => $self->_i18n('error_path_required') },
			status => 400,
		);
	}

	my $file = eval { Mojo::File->new($path)->realpath };
	# Restrict to files with a supported data extension so stat_api cannot be
	# used as a filesystem oracle to probe /etc/shadow, /root/.ssh/, etc.
	return $self->render(json => { exists => \0, path => $path })
		unless defined $file && -f $file && $file->basename =~ $EXT_RE;

	my @s = stat $file->to_string;
	$self->render(json => {
		exists => \1,
		path   => $file->to_string,
		mtime  => $s[9],
		size   => $s[7],
	});
}

=head2 upload_file

C<POST /upload> -- Accept a drag-and-dropped data file and return a redirect URL.

The file is saved under its original filename in a managed subdirectory of
C<< <app_home>/.uploads/ >>.  The subdirectory name is randomised so that
concurrent uploads of files with the same name do not collide.

=head3 API SPECIFICATION

=head4 INPUT

Multipart form upload, field name: C<file>.

  file   upload   Supported extensions: csv, db, sql, xml, psv.

=head4 OUTPUT

  200 application/json   { "url": "/open?path=/abs/path/file.csv", "path": "/abs/path/file.csv" }
  400 application/json   { "error": "No file received" }
  415 application/json   { "error": "Unsupported file type. Accepted: ..." }

=head3 MESSAGES

  error_upload_none   -- no file was received in the multipart upload.
  error_upload_ext    -- the file's extension is not in the supported list.

=head3 FORMAL SPECIFICATION

  upload_file == lambda self .
    let upload = req.upload('file') in
    pre  upload /= undef /\ basename(upload.filename) =~ EXT_RE
    let dest = home/.uploads/<random>/<filename> in
    post upload.move_to(dest)
         /\ render_json({ url: '/open?path=' ++ url_escape(dest), path: dest })

=head3 EXAMPLE

  POST /upload  (multipart: file=@sales.csv)
    -> { "url": "/open?path=%2F...%2Fsales.csv", "path": "/.../.uploads/abc123/sales.csv" }

=cut

sub upload_file ($self) {
	my $upload = $self->req->upload('file');
	unless ($upload && $upload->filename) {
		return $self->render(
			json   => { error => $self->_i18n('error_upload_none') },
			status => 400,
		);
	}

	# Enforce upload size limit.  max_request_size in startup() sets the
	# transport-layer cap, but Mojolicious still calls the controller when the
	# limit fires (with req->is_limit_exceeded true and partial content in the
	# upload asset).  Check is_limit_exceeded first; fall through to an asset
	# size check as a belt-and-braces guard for any bytes that slipped through.
	if ($self->req->is_limit_exceeded || $upload->size > $MAX_UPLOAD_BYTES) {
		return $self->render(
			json   => { error => $self->_i18n('error_upload_too_large', $MAX_UPLOAD_MIB) },
			status => 413,
		);
	}

	# /s so .* matches \n; a percent-decoded newline inside a browser filename
	# must not silently truncate the directory-strip, leaving "dir\ncomponent" in.
	(my $filename = $upload->filename) =~ s{.*[/\\]}{}s;
	unless ($filename && $filename =~ $EXT_RE) {
		return $self->render(
			json   => { error => $self->_i18n('error_upload_ext') },
			status => 415,
		);
	}

	# Store uploads in <app_home>/.uploads/<random_subdir>/<original_filename>.
	# Using the original filename is essential: Database::Abstraction derives
	# the table name from the file stem, so "sales.csv" must stay "sales.csv".
	# The random subdirectory prevents collisions from concurrent same-name uploads.
	my $uploads_base = $self->app->home->child('.uploads');
	$uploads_base->make_path unless -d $uploads_base;
	my $sub_dir = tempdir(DIR => $uploads_base->to_string, CLEANUP => 0);
	my $dest    = Mojo::File->new($sub_dir)->child($filename)->to_string;
	$upload->move_to($dest);

	$self->render(json => {
		url  => '/open?path=' . url_escape($dest),
		path => $dest,
	});
}

sub clear_uploads ($self) {
	my $uploads_dir = $self->app->home->child('.uploads');

	return $self->render(json => { freed => 0, count => 0 })
		unless -d $uploads_dir;

	my ($freed, $count) = (0, 0);

	# Each upload lands in <uploads_dir>/<random_subdir>/<filename>.
	# Iterate the subdirs, tally file sizes, then remove each subdir tree.
	$uploads_dir->list({ dir => 1 })->each(sub {
		my ($entry) = @_;
		if (-d $entry) {
			$entry->list->each(sub {
				my ($file) = @_;
				return unless -f $file;
				$freed += (-s $file) // 0;
				$count++;
			});
			$entry->remove_tree;
		} elsif (-f $entry) {
			$freed += (-s $entry) // 0;
			$count++;
			unlink $entry->to_string;
		}
	});

	$self->render(json => { freed => $freed, count => $count });
}

# graph_view
#
# Purpose: Render a D3.js line chart from the current data pipeline.
# Entry:   Query params identical to /join (l=, j=, c=, f=, d=) plus:
#            x=<column>  -- X-axis column name
#            y=<column>  -- Y-axis column name (values must be numeric)
#            back=<url>  -- URL for the "Back to table" link (set by JS)
# Exit:    Emits a TT-rendered HTML page with a brush-to-zoom HTML::D3 snippet.
#          Each data point carries an "extra" hash of every column not used
#          as the X or Y axis; HTML::D3 displays these in the hover tooltip.
#          A "Reset zoom" button appears after the user brushes to zoom in.
#          Returns HTTP 400 for missing/invalid column names, 404 if the
#          data source cannot be opened, 200 with an error message when
#          no plottable rows exist.
sub graph_view ($self) {
	my $x_col = $self->param('x') // '';
	my $y_col = $self->param('y') // '';
	my $back  = $self->param('back') // '/';

	return $self->render(text => 'Missing x or y column parameter', status => 400)
		unless length($x_col) && length($y_col);

	my ($records, $columns) = $self->_run_export_pipeline;
	return $self->render(text => 'Could not open data source', status => 404)
		unless $records;

	my %col_set = map { $_ => 1 } @{$columns};
	return $self->render(text => "Column not found: $x_col", status => 400)
		unless $col_set{$x_col};
	return $self->render(text => "Column not found: $y_col", status => 400)
		unless $col_set{$y_col};

	# Extract [label, value] pairs; skip rows where Y is missing or non-numeric.
	my @pairs;
	for my $row (@{$records}) {
		my $x = $row->{$x_col} // '';
		my $y = $row->{$y_col} // '';
		next unless length($x) && length($y);
		my $is_acct_neg = ($y =~ /\A\s*\(/);   # (value) = accounting negative
		(my $y_num = $y) =~ s/[^\d.\-]//g;
		$y_num = "-$y_num" if $is_acct_neg && $y_num =~ /\A\d/;
		next unless $y_num =~ /\A-?\d+(?:\.\d+)?\z/;
		my %extra = map { $_ => $row->{$_} } grep { $_ ne $x_col && $_ ne $y_col } @{$columns};
		push @pairs, [$x, $y_num + 0, \%extra];
	}

	return $self->render(
		text   => 'No plottable data: no rows have valid numeric values in the Y column.',
		status => 200,
	) unless @pairs;

	my @y_vals  = map { $_->[1] } @pairs;
	my $min_y   = min(@y_vals);
	my $max_y   = max(@y_vals);
	my $avg_y   = sum(@y_vals) / scalar(@y_vals);

	require HTML::D3;
	my $title   = "$y_col vs $x_col";
	my $snippet = HTML::D3->new(title => $title, width => 1100, height => 580)
		->render_zoomable_line_chart_snippet(\@pairs);

	my ($platform, $language) = $self->_resolve_template;
	$self->render(
		handler      => 'tt',
		template     => "$platform/$language/graph",
		format       => 'html',
		title        => $title,
		graph_html   => $snippet->{html},
		back_url     => $back,
		back_label   => 'Back to table',
		point_count  => scalar @pairs,
		ref_min_y    => $min_y,
		ref_max_y    => $max_y,
		ref_avg_y    => sprintf('%.4g', $avg_y),
	);
}

1;

__END__

=head1 NAME

Database::BI::Controller::Dashboard - Home picker, filesystem browser, table
viewer, left-join engine, result filter, export, and file upload

=head1 SYNOPSIS

All routes in C<Database::BI> are handled by this controller.  You do not
call its methods directly -- Mojolicious dispatches HTTP requests to them
automatically.  The examples below show browser URLs and their curl
equivalents.

B<Open the home page and see all tables in the data directory:>

  # Browser
  http://localhost:3000/

  # curl
  curl http://localhost:3000/

B<View a single table (file: data/sales.csv):>

  # Browser
  http://localhost:3000/view/sales

  # curl
  curl http://localhost:3000/view/sales

B<Filter rows -- show only rows where region equals "North":>

  # Browser (add ?f=col:op:val to any view URL)
  http://localhost:3000/view/sales?f=region:eq:North

  # Multiple filters -- "North" AND amount greater than 100:
  http://localhost:3000/view/sales?f=region:eq:North&f=amount:gt:100

  # curl
  curl 'http://localhost:3000/view/sales?f=region:eq:North'

B<Join two tables -- left-join sales with products on the product column:>

  # Browser
  http://localhost:3000/join?l=table:sales&j=table:products|product|name

  # The j= parameter is: right-table-spec | left-key | right-key
  # You can chain multiple joins:
  http://localhost:3000/join?l=table:sales&j=table:products|product|name&j=table:regions|region|id

B<Open a file anywhere on the filesystem (not just in data/):>

  http://localhost:3000/open?path=/home/user/reports/q3.csv

B<Download the current view as a CSV file:>

  # Uses the same l=, j=, f= parameters as /join
  http://localhost:3000/export?l=table:sales&format=csv

  # Download as a SQLite database file instead:
  http://localhost:3000/export?l=table:sales&format=sqlite

  # Download a filtered + joined result:
  http://localhost:3000/export?l=table:sales&j=table:products|product|name&f=region:eq:North&format=csv

B<Save the current view to a file on the server (instead of downloading):>

  # POST with form fields; format is inferred from the filename extension
  curl -X POST http://localhost:3000/export \
       -F l=table:sales \
       -F dir=/home/user/exports \
       -F filename=report.csv

  # Save as SQLite:
  curl -X POST http://localhost:3000/export \
       -F l=table:sales \
       -F dir=/home/user/exports \
       -F filename=report.sql

B<Get the column list for a table (used by the join UI):>

  curl http://localhost:3000/api/columns?table=sales
  # Returns: {"columns":["product","region","amount","date"]}

B<Check when a file was last modified (used by the tooltip on the home page):>

  curl 'http://localhost:3000/api/stat?path=/data/sales.csv'
  # Returns: {"exists":true,"path":"/data/sales.csv","mtime":1700000000,"size":1234}

B<Browse the filesystem to find a data file:>

  http://localhost:3000/browse
  http://localhost:3000/browse?path=/home/user/data

B<Upload a data file by dropping it onto the page (multipart form POST):>

  curl -X POST http://localhost:3000/upload \
       -F file=@/home/user/data/sales.csv
  # Returns: {"url":"/open?path=/.../.uploads/.../sales.csv","path":"/.../.uploads/.../sales.csv"}

=head2 graph_view

C<GET /graph> -- Render a D3.js v7 line chart from the current data pipeline.

Accepts the same pipeline parameters as L</join_tables> (C<l=>, C<j=>,
C<c=>, C<f=>, C<d=>) plus:

=over 4

=item C<x=E<lt>colE<gt>>

Column name to use as the X axis (required).  Any data type is accepted;
values are displayed as categorical labels.

=item C<y=E<lt>colE<gt>>

Column name to use as the Y axis (required).  Non-numeric characters
(currency symbols, commas, etc.) are stripped before comparison; rows
where the value is still non-numeric after stripping are silently skipped.

=item C<back=E<lt>urlE<gt>>

URL for the "Back to table" link rendered in the graph toolbar.  Defaults
to C</> when absent.  The dashboard JS sets this to the current page URL
before navigating.

=back

=head3 API SPECIFICATION

=head4 INPUT

  l=<spec>     string   Left-table spec (required).  Same syntax as /join.
  x=<col>      string   X-axis column name (required).
  y=<col>      string   Y-axis column name (required; must be numeric).
  back=<url>   string   Back-link URL (optional; default "/").
  j=, c=, f=, d=        Pipeline params -- see L</join_tables>.

=head4 OUTPUT

  200 text/html   TT-rendered graph page.  The HTML::D3 snippet embeds a
                  C<const data = [...]> JSON array where each element has:
                    { label: <x-value>, value: <y-value>,
                      extra: { <col>: <val>, ... } }
                  C<extra> contains every column not used as X or Y, so
                  the hover tooltip shows the complete row for each point.
                  The chart supports brush-to-zoom; a "Reset zoom" button
                  appears after a brush selection.  The toolbar shows the
                  count of plotted data points.

  400 text/plain  C<x=> or C<y=> absent, or named column not found.
  404 text/plain  Data source could not be opened.

=head3 MESSAGES

  Missing x or y column parameter          C<x=> or C<y=> query param absent.
  Column not found: <name>                  Named column absent from result set.
  Could not open data source                Left-table spec unresolvable or 404.
  No plottable data: no rows have valid ... All rows lack a numeric Y value.

=head3 EXAMPLE

  GET /graph?l=table:sales&x=product&y=amount

Renders a line chart of C<amount> (Y) against C<product> (X).  Mousing over
a dot shows a tooltip with the product name, the amount, and every other
column in that row (e.g. C<region>, C<date>).

=head3 FORMAL SPECIFICATION

  graph_view : Controller × Params → HTML | Error

  let pipeline = run_export_pipeline(l, j, c, f, d)
  let pairs    = [ [row[x], num(row[y]), row \ {x,y}]
                   | row ∈ pipeline.records,  num(row[y]) ≠ ⊥ ]

  pre  x ∈ params ∧ y ∈ params           else 400
  pre  x ∈ pipeline.cols                  else 400
  pre  y ∈ pipeline.cols                  else 400
  pre  pairs ≠ []                          else 200 "No plottable data"
  post HTML::D3->render_line_chart_snippet(pairs) embedded in TT layout

=cut

=head2 clear_uploads

C<POST /uploads/clear> -- Delete every file from the C<.uploads/> staging
directory and return the total disk space recovered.

The C<.uploads/> directory accumulates files from drag-and-drop uploads.
It grows indefinitely; this action lets users reclaim that space without
needing shell access.

=head3 API SPECIFICATION

=head4 INPUT

No parameters.  The C<.uploads/> path is always the one under C<app->home>.

=head4 OUTPUT

  200 application/json   { "freed": <bytes>, "count": <n> }

C<freed> is the total number of bytes removed.  C<count> is the number of
files deleted.  Both are 0 when the directory is absent or already empty.

=cut

=head1 DESCRIPTION

All user-facing routes in C<Database::BI> are handled by this controller.
See the individual action POD above for per-endpoint documentation.

=head2 Filter operators

The C<f=col:op:val> filter spec supports:

  eq        case-insensitive string equality
  ne        case-insensitive string inequality
  contains  case-insensitive substring match
  starts    case-insensitive prefix match
  lt        numeric less-than
  le        numeric less-than-or-equal
  gt        numeric greater-than
  ge        numeric greater-than-or-equal
  empty     cell is undef or empty string (val ignored)
  notempty  cell is defined and non-empty (val ignored)

The colon separator is split with a limit of 3, so values may themselves
contain colons (e.g. C<f=sale_date:eq:2025-01-15>).

=head1 COMMON PITFALLS

These are the most common mistakes when working with this controller.

=over 4

=item B<SQLite files must use the .sql extension, not .sqlite>

C<Database::Abstraction> (the data-reading library) probes for a file called
C<tablename.sql> when it wants to open a SQLite database.  It does B<not>
look for C<.sqlite> or C<.db3>.  If your file is called C<inventory.sqlite>,
rename it to C<inventory.sql> or it will not appear in the file browser and
will return 404 when opened.

=item B<Filter values that contain a colon still work>

A date like C<2025-01-15> contains hyphens, not colons, so it is fine.  But
if your value itself contains a colon (for example, a time like C<14:30:00>),
the filter still works because the C<col:op:val> spec is split on the B<first
two> colons only -- the rest of the string becomes the value.

  # This correctly matches "14:30:00" in the start_time column:
  ?f=start_time:eq:14:30:00

=item B<Left join keeps only the FIRST matching right-table row>

When the right table has two rows with the same join key, only the first one
(in file order) is used.  The second is silently ignored.  If you need all
matches, consider pre-processing your data so join keys are unique.

=item B<Export format comes from the filename extension, not a Content-Type header>

When using C<POST /export> to save a file to disk, the format (CSV or SQLite)
is determined by the extension of the C<filename> parameter.  C<.csv> produces
a CSV file; C<.sql> produces a SQLite database.  Any other extension returns
HTTP 415 (Unsupported Media Type).  The C<Content-Type> request header is
ignored entirely.

=item B<Template Toolkit variables starting with underscore are silently dropped>

If you add a stash variable with a name starting with C<_> (for example,
C<_tmp> or C<_result>), Template Toolkit will silently produce an empty string
when the template tries to read it.  This is a TT quirk when C<TRIM =E<gt> 1>
is active.  Always use names that start with a letter.

=item B<_apply_filter_spec always passes all records through for unknown operators>

If you pass an operator that is not in the supported list (for example C<regex>
or C<like>), the filter is treated as a no-op and B<all rows are returned>.  No
error is produced.  This is intentional so that future operators can be added
without breaking existing clients that read a wider response.

=item B<Uploading a file does not clean up automatically>

Files uploaded via C<POST /upload> are stored in C<.uploads/> under the
application's home directory and are B<never deleted automatically>.  They
accumulate until you manually remove the C<.uploads/> directory.  This is
intentional for a single-user local tool, but you should be aware of it on
long-running servers.

=item B<Open C<data/> tables by name; open other files by absolute path>

The C<view> action (C<GET /view/:table>) only looks inside C<data_dir>.
To open a file from anywhere else on the filesystem, use C<open_file>
(C<GET /open?path=/abs/path>).  The two routes use different URL schemes and
are not interchangeable.

=back

=head1 LIMITATIONS

=over 4

=item *

The in-memory left join in C<_left_join> holds both the left and right result
sets in RAM simultaneously.  For files with millions of rows, replace the
C<open_table> helper in C<Database::BI> with a C<Database::Join> backend
without changing this controller.

=item *

C<_resolve_language> extracts only the primary language subtag from the first
C<Accept-Language> tag (e.g. C<de> from C<de-DE,de;q=0.9,en;q=0.8>).
Quality weights and multiple alternatives are not ranked.

=item *

No GeoIP-based language resolution is implemented.  The language is resolved
from the HTTP C<Accept-Language> header only.

=item *

C<Sub::Protected> enforcement requires the CHECK compilation phase; when modules
are loaded dynamically at test time the "Too late to run CHECK block" warning
is emitted and the restriction is not enforced in that context.

=back

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
