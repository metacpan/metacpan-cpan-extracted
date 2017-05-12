package ALPM::Conf;
use warnings;
use strict;

BEGIN {
	require Carp;
	require ALPM;
}

## Private functions.

# These options are implemented in pacman, not libalpm, and are ignored.
my @NULL_OPTS = qw{HoldPkg SyncFirst CleanMethod XferCommand
	TotalDownload VerbosePkgLists};

sub _null
{
	1;
}

my $COMMENT_MATCH = qr/ \A \s* [#] /xms;
my $SECTION_MATCH = qr/ \A \s* \[ ([^\]]+) \] \s* \z /xms;
my $FIELD_MATCH = qr/ \A \s* ([^=\s]+) (?: \s* = \s* ([^\n]*))? /xms;
sub _mkparser
{
	my($path, $hooks) = @_;
	sub {
		local $_ = shift;
		s/^\s+//; s/\s+$//; # trim whitespace
		return unless(length);

		# Call the appropriate hook for each type of token...
		if(/$COMMENT_MATCH/){
			;
		}elsif(/$SECTION_MATCH/){
			$hooks->{'section'}->($1);
		}elsif(/$FIELD_MATCH/){
			my($name, $val) = ($1, $2);
			if(length $val){
				my $apply = $hooks->{'field'}{$name};
				$apply->($val) if($apply);
			}
		}else{
			die "Invalid line in config file, not a comment, section, or field\n";
		}
	};
}

sub _parse
{
	my($path, $hooks) = @_;

	my $parser = _mkparser($path, $hooks);
	my $line;
	open my $if, '<', $path or die "open $path: $!\n";
	eval {
		while(<$if>){
			chomp;
			$line = $_;
			$parser->($_);
		}
	};
	my $err = $@;
	close $if;
	if($err){
		# Print the offending file and line number along with any errors...
		# (This is why we use dies with newlines, for cascading error msgs)
		die "$@$path:$. $line\n"
	}
	return;
}

## Public methods.

sub new
{
	my($class, $path) = @_;
	bless { 'path' => $path }, $class;
}

sub custom_fields
{
	my($self, %cfields) = @_;
	if(grep { ref $_ ne 'CODE' } values %cfields){
		Carp::croak('Hash argument must have coderefs as values' )
	}
	$self->{'cfields'} = \%cfields;
	return;
}

sub _mlisthooks
{
	my($dbsref, $sectref) = @_;

	# Setup hooks for 'Include'ed file parsers...
	return {
		'section' => sub {
			my $file = shift;
			die q{Section declaration is not allowed in Include-ed file\n($file)\n};
		},
		'field' => {
			'Server' => sub { _addmirror($dbsref, shift, $$sectref) }
		},
	 };
}

my %CFGOPTS = (
	'RootDir' => 'root',
	'DBPath' => 'dbpath',
	'CacheDir' => 'cachedirs',
	'GPGDir' => 'gpgdir',
	'LogFile' => 'logfile',
	'UseSyslog' => 'usesyslog',
	'UseDelta' => 'usedelta',
	'CheckSpace' => 'checkspace',
	'IgnorePkg' => 'ignorepkgs',
	'IgnoreGroup' => 'ignoregrps',
	'NoUpgrade' => 'noupgrades',
	'NoExtract' => 'noextracts',
	'NoPassiveFtp' => 'nopassiveftp',
	'Architecture' => 'arch',
);

sub _confhooks
{
	my($optsref, $sectref) = @_;
	my %hooks;
	while(my($fld, $opt) = each %CFGOPTS){
		$hooks{$fld} = sub { 
			my $val = shift;
			die qq{$fld can only be set in the [options] section\n}
				unless($$sectref eq 'options');
			$optsref->{$opt} = $val;
		};
	 }
	return %hooks;
}

sub _nullhooks
{
	map { ($_ => \&_null) } @_
}

sub _getdb
{
	my($dbs, $name) = @_;

	# The order databases are added must be preserved as must the order of URLs.
	for my $db (@$dbs){
		return $db if($db->{'name'} eq $name);
	}
	my $new = { 'name' => $name };
	push @$dbs, $new;
	return $new;
}

sub _setsiglvl
{
	my($dbs, $sect, $siglvl) = @_;
	my $db = _getdb($dbs, $sect);
	$db->{'siglvl'} = $siglvl;
	return;
}

sub _parse_siglvl
{
	my($str) = @_;
	my $siglvl;

	my $opt;
	for(split /\s+/, $str){
		my @types = qw/pkg db/;

		if(s/^Package//){
			@types = qw/pkg/;
		}elsif(s/^Database//){
			@types = qw/db/;
		}

		if(/^Never$/){
			$opt->{$_} = 'never' for(@types);
		}elsif(/^Optional$/){
			$opt->{$_} = 'optional' for(@types);
		}elsif(/^Required$/){
			$opt->{$_} = 'required' for(@types);
		}elsif(/^TrustedOnly$/){
			;
		}elsif(/^TrustAll$/){
			for my $t (@types){
				$opt->{$t} = 'optional' unless(defined $opt->{$t});
				$opt->{$t} .= ' trustall';
			}
		}else{
			die "Unknown SigLevel option: $_\n";
		}
	}

	# Check for a blank SigLevel
	unless(defined $opt){
		die "SigLevel was empty\n";
	}
	return $opt;
}

sub _addmirror
{
	my($dbs, $url, $sect) = @_;
	die "Section has not previously been declared, cannot set URL\n" unless($sect);

	my $db = _getdb($dbs, $sect);
	push @{$db->{'mirrors'}}, $url;
	return;
}


sub _setopt
{
	my($alpm, $opt, $valstr) = @_;
	no strict 'refs';
	my $meth = *{"ALPM::set_$opt"}{'CODE'};
	die "The ALPM::set_$opt method is missing" unless($meth);

	my @val = ($opt =~ /s$/ ? map { split } $valstr : $valstr);
	return $meth->($alpm, @val);
}

sub _setarch
{
	my($opts) = @_;
	if(!$opts->{'arch'} || $opts->{'arch'} eq 'auto'){
		chomp ($opts->{'arch'} = `uname -m`);
	}
}

sub _expurls
{
	my($urls, $arch, $repo) = @_;
	for(@$urls){
		s/\$arch/$arch/g;
		s/\$repo/$repo/g;
	}
}

sub _applyopts
{
	my($opts, $dbs) = @_;
	my($root, $dbpath) = delete @{$opts}{'root', 'dbpath'};

	unless($root){
		$root = '/';
		unless($dbpath){
			$dbpath = "$root/var/lib/pacman";
			$dbpath =~ tr{/}{/}s;
		}
	}

	my $alpm = ALPM->new($root, $dbpath);

	_setarch($opts);
	while(my ($opt, $val) = each %$opts){
		# The SetOption type in typemap croaks on error, no need to check.
		_setopt($alpm, $opt, $val);
	}

	my $usesl = grep { /signatures/ } $alpm->caps;
	for my $db (@$dbs){
		my($r, $sl, $mirs) = @{$db}{'name', 'siglvl', 'mirrors'};
		next if(!@$mirs);

		_expurls($mirs, $opts->{'arch'}, $r);
		$sl = 'default' if(!$usesl);
		my $x = $alpm->register($r, $sl)
			or die "Failed to register $r database: " . $alpm->strerror;
		$x->add_server($_) for(@$mirs);
	}
	return $alpm;
}

sub parse
{
	my($self) = @_;

	my (%opts, @dbs, $currsect, $defsiglvl);
	my %fldhooks = (
		_confhooks(\%opts, \$currsect),
		_nullhooks(@NULL_OPTS),
		'Server'  => sub { _addmirror(\@dbs, shift, $currsect) },
		'Include' => sub {
			die "Cannot have an Include directive in the [options] section\n"
				if($currsect eq 'options');

			# An include directive spawns its own little parser...
			_parse(shift, _mlisthooks(\@dbs, \$currsect));
		},
		'SigLevel' => sub {
			if($currsect eq 'options'){
				$defsiglvl = _parse_siglvl(shift);
			}else{
				_setsiglvl(\@dbs, $currsect, _parse_siglvl(shift));
			}
		},
		($self->{'cfields'} ? %{$self->{'cfields'}} : ()),
	);

	my %hooks = (
		'field' => \%fldhooks,
		'section' => sub { $currsect = shift; }
	);

	_parse($self->{'path'}, \%hooks);
	return _applyopts(\%opts, \@dbs);
}

## Import magic used for quick scripting.
# e.g: perl -MALPM::Conf=/etc/pacman.conf -le 'print $alpm->root'

sub import
{
	my($pkg, $path) = @_;
	my($dest) = caller;
	return unless($path);

	my $conf = $pkg->new($path);
	my $alpm = $conf->parse;
	no strict 'refs';
	*{"${dest}::alpm"} = \$alpm;
	return;
}

1;
