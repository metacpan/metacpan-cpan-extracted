package App::Mowyw;
use strict;
use warnings;
#use warnings FATAL => 'all';

our $VERSION = '0.8.0';

use App::Mowyw::Lexer qw(lex);
use App::Mowyw::Datasource;

use File::Temp qw(tempfile);
use File::Compare;
use Carp;
use Storable qw(dclone);
use Scalar::Util qw(reftype blessed);
use File::Copy;
use Encode qw(encode decode);
use Config::File qw(read_config_file);

use Exporter qw(import);
use Data::Dumper;
use Carp qw(confess);
binmode STDOUT, ':encoding(UTF-8)';

our @EXPORT_OK = qw(
        get_config
        parse_file
        process_dir
        process_file
        parse_str
        parse_all_in_dir
);

our %config = (
        default => {
            include => 'includes/',
            source  => 'source/',
            online  => 'online/',
            postfix => '',
        },
        encoding    => 'utf-8',
        file_filter => [
            [1, 10, qr{\..?htm}],
        ],
);
$config{default}{menu} = $config{default}{include} . 'menu-';

my $internal_error_message = "Please contact the Author at moritz\@faui2k3.org providing\nan example how to reproduce the error, including the complete error message";

my @input_tokens = (
        [ 'TAG_START',      qr/\[\[\[\s*/],
        [ 'TAG_START',      qr/\[\%\s*/],
        [ 'KEYWORD',        qr/(?:
             include
            |menu
            |system
            |option
            |item
            |endverbatim
            |verbatim
            |comment
            |setvar
            |readvar
            |synatxfile
            |syntax
            |endsyntax
            |bind
            |for
            |endfor
            |ifvar
            |endifvar
            )/x                         ],
        [ 'TAG_END',        qr/\s*\]\]\]/],
        [ 'TAG_END',        qr/\s*\%\]/],
        [ 'BRACES_START',   qr/\{\{/],
        [ 'BRACES_END',     qr/\}\}/],
    );

sub parse_all_in_dir {
    my @todo = @_;
    while (defined(my $fn = pop @todo)){
        $fn .= '/' unless ($fn =~ m#/$#);
        opendir my $DIR, $fn or die "Cannot opend directory '$fn' for reading: $!";
        IW: while (my $f = readdir $DIR){
            # ignore symbolic links and non-Readable files:
            next IW if (-l $f);
            # if we consider . and .., we loop infinetly.
            # and while we are at ignoring, we can ignore a few
            # other things as well ;-)
            if (
                       $f eq '..'
                    or $f eq '.'
                    or $f eq  '.svn'
                    or $f eq  '.git'
                    or $f =~ m{(?:~|\.swp)$}){
                next;
            }
            $f = $fn . $f;
            if (-d $f){
                push @todo, $f;
                process_dir($f);
            } else {
                process_file($f);
            }
        }
        closedir $DIR;
    }
}

sub process_dir {
    my $fn = shift;
    my $new_fn = get_online_fn($fn);
    mkdir $new_fn;
}

# strip leading and trailing whitespaces from a string 
sub strip_ws {
    my $s = shift;
    $s =~ s/^\s+//g;
    $s =~ s/\s+$//g;
    return $s;
}

sub escape {
    my $str = shift;
    my %esc = (
        "\\"    => '\\\\',
        "\t"    => '\t',
        "\n"    => '\n',
    );
    my $re = join '|', map quotemeta, keys %esc;
    $str =~ s/($re)/$esc{$1}/g;
    return $str;
}

sub parse_error {
    my $message = shift;
    my @filenames = @{shift()};
    my $token = shift;
    my $str = "Parse error in file '$filenames[0]': $message\n";
    if ($token) {
        $str .= "in line $token->[3] near'" . escape($token->[0]) ."'\n";
    }
    for (@filenames[0..$#filenames]) {
       $str .= "    ...included from file '$_'\n";
    }
    confess $str;
    exit 1;
}

# parse sub: anything is treated as normal text that does not start or end a
# command
# the second (optional) arg contains a hash of additional tokens that are
# treated as plain text
sub p_text {
    my $tokens = shift;
    my %a;
    %a = %{$_[0]} if ($_[0]);
    my $str = "";
    my %allowed_tokens = (
            KEYWORD => 1,
            UNMATCHED => 1,
            );

    while (     $tokens
            and $tokens->[0]
            and $tokens->[0]->[0]
            and ($allowed_tokens{$tokens->[0]->[0]}
                or $a{$tokens->[0]->[0]})){

        $str .= $tokens->[0]->[1];
        shift @$tokens;
    }
    return $str;
}

# parse sub: parse an include statement.
# note that TAG_START and the keyword "include" are already stripped
sub p_include {
    my $tokens = shift;
    my $meta = shift;
    # normally we'd expect an UNMATCHED token, but the user might choose
    # a keyword as well as file name
    my $fn = strip_ws(slurp_upto_token($tokens, 'TAG_END', $meta));
    $fn = get_include_filename('include', $fn, $meta->{FILES}->[-1]);
#    print Dumper $tokens;
    my $m = my_dclone($meta);
    unshift @{$m->{FILES}}, $fn;
    return parse_file($fn, $m);
}

# parse sub: parse a system statement.
sub p_system {
    my $tokens = shift;
    my $meta = shift;
    my $fn = strip_ws(slurp_upto_token($tokens, 'TAG_END', $meta));
    print STDERR "Executing external command '$fn'\n" unless $config{quiet};
    my $tmp = `$fn`;
    return ($tmp);
}

# parse sub: parse a 'menu' statement.
# note that TAG_START and the keyword "menu" are already stripped
sub p_menu {
    my $tokens = shift;
    my $meta = shift;
#    print Dumper $meta;
    my $key = strip_ws(p_expect($tokens, "UNMATCHED", $meta));
    my @words = split /\s+/, $key;
    p_expect($tokens, "TAG_END", $meta);
    my $menu_fn = shift @words;
#    print "\nMenu: '$menu_fn'\n";
    $menu_fn = get_include_filename('menu', $menu_fn, $meta->{FILES}->[-1]);
#    print "Menu after frobbing: '$menu_fn'\n";

    my $m = my_dclone($meta);
    push @{$m->{ITEMS}}, @words;
    unshift @{$m->{FILES}}, $menu_fn;
    return parse_file($menu_fn, $m);
}

# parse sub: parse an 'option' statement
sub p_option {
    my $tokens = shift;
    my $meta = shift;
    my $key = strip_ws(p_expect($tokens, "UNMATCHED", $meta));
    my @words = split /\s+/, $key;
    my $option_key = shift @words;
    my $option_val = join " ", @words;
    $meta->{OPTIONS}->{$option_key} = $option_val;
    p_expect($tokens, "TAG_END", $meta);
    return "";
}

#parse sub: parse an "item" statement
sub p_item {
    my $tokens = shift;
    my $meta = shift;
    my $content = p_expect($tokens, "UNMATCHED", $meta);
    $content =~ s/^\s+//;
    $content =~ m/^(\S+)/;
    my $key = $1;
    $content =~ s/^\S+//;

    my $m = my_dclone($meta);
#   print Data::Dumper->Dump([$m]);
    if ($meta->{ITEMS}->[0] and $meta->{ITEMS}->[0] eq $key){
        shift @{$m->{ITEMS}};
        $m->{CURRENT_ITEM} = $key;

    } else {
        $m->{ITEMS} = [];
        $m->{CURRENT_ITEM} = undef;
    }
    $m->{INSIDE_ITEM} = 1;
    my $str = $content . parse_tokens($tokens, $m);
    p_expect($tokens, "TAG_END", $meta);
    return $str;

}

sub p_bind {
    my ($tokens, $meta) = @_;
    my $contents = strip_ws(slurp_upto_token($tokens, 'TAG_END', $meta));
    my ($var, $rest) = split m/\s+/, $contents, 2;
    my $string = qr{(
         '[^'\\]*(?>\\.[^'\\]*)*'
        |"[^"\\]*(?>\\.[^"\\]*)*'
        |[^"']\S*
    )}x;
    my %options = parse_hash($rest, 'bind', $meta);

    if ($options{file}){
        $options{file} = get_include_filename('include', $options{file}, $meta->{FILES}->[-1]);
    }
    $meta->{VARS}{$var} = App::Mowyw::Datasource->new(\%options);

    return '';
}

sub p_for {
    my ($tokens, $meta) = @_;
    my $contents = strip_ws(slurp_upto_token($tokens, 'TAG_END', $meta));
    my ($iter, $in, $datasource) = split m/\s+/, $contents;
    if (!defined $datasource || lc $in ne 'in' ){
        parse_error(
                q{Can't parse for statement. Syntax is [% for iterator_var in datasource %] ... [% endfor %]},
                $meta->{FILES},
                $tokens->[0],
        );
    }
    my $ds = $meta->{VARS}{$datasource};
    if (!$ds || !blessed($ds)){
        confess "'$datasource' is not defined or not a valid data source\n";
    }

    my @bck_tokens = @$tokens;
    my $str = '';
    $ds->reset();
    while (!$ds->is_exhausted){
        local $meta->{VARS}{$iter} = $ds->get();
        local $meta->{PARSE_UPTO} = 'endfor';
        @$tokens = @bck_tokens;
#        print "Iterating over '$datasource'\n";
        $str .= parse_tokens($tokens, $meta);
        $ds->next();
    }
    return $str;
}

sub p_ifvar {
    my ($tokens, $meta) = @_;
    my $contents = strip_ws(slurp_upto_token($tokens, 'TAG_END', $meta));
    if ($contents =~ m/\s/){
        parse_error(
            q{Parse error in 'ifvar' tag. Syntax is [% ifvar variable %] .. [% endifvar %]},
            $meta->{FILES},
            $tokens->[0],
        );
    }
    my $c = do {
        local $meta->{NO_VAR_WARN} = 1;
        resolve_var($contents, $meta);
    };
    local $meta->{PARSE_UPTO} = 'endifvar';
    if (defined $c){
#        warn "Variable '$contents' is defined\n";
        return parse_tokens($tokens, $meta); 
    } else {
#        warn "Variable '$contents' is NOT defined\n";
        local $meta->{NO_VAR_WARN} = 1;
        parse_tokens($tokens, $meta); 
        return '';
    }
}

sub p_verbatim {
    my $tokens = shift;
    my $meta = shift;
    my $str = "";
    my $key = strip_ws(slurp_upto_token($tokens, 'TAG_END', $meta));
#    print Dumper $tokens;
    while (@$tokens){
        if (    $tokens->[0]->[0] eq "TAG_START" 
            and $tokens->[1]->[0] eq "KEYWORD"
            and $tokens->[1]->[1] eq "endverbatim"
            and $tokens->[2]->[1] =~ m/\s*\Q$key\E\s*/
            and $tokens->[3]->[0] eq "TAG_END"){

            # found end of verbatim section
            shift @$tokens for 1 .. 4;
            return $str;
        } else {
            $str .= $tokens->[0]->[1]; 
            shift @$tokens;
        }
    }
    die "[[[verbatim $key]]] opened but not closed until end of file\n";
}

sub p_comment {
    my $tokens = shift;
    my $meta = shift;
    slurp_upto_token($tokens, 'TAG_END', $meta);
    return "";
}


sub resolve_var {
    my ($name, $meta) = @_;
    if ($name =~ m/\./){
        my @parts = split m/\./, $name;
        my $var = $meta->{VARS};
        for (@parts){
            if (!defined $var || !ref $var || reftype($var) ne 'HASH'){
                unless ($meta->{NO_VAR_WARN}){
                    warn "\nCan't dereference '$name' at level '$_': not defined or not a hash\n";
                }
                return undef;
            }
            $var = $var->{$_};
        }
        return $var;
    }
    if (exists $meta->{VARS}->{$name}){
        return $meta->{VARS}->{$name};
    } else {
        unless ($meta->{NO_VAR_WARN} || $config{quiet}){
            print STDERR "Trying to access variable '$name' which is not defined\n";
        }
        return undef;
    }
}

sub encode_entities {
    my $str = shift;
    return '' unless defined $str;
    $str =~ s{&}{&amp;}g;
    $str =~ s{<}{&lt;}g;
    $str =~ s{>}{&gt;}g;
    $str =~ s{"}{&quot;}g;
    return $str;
}

sub slurp_upto_token {
    my ($tokens, $expected_token, $meta) = @_;
    my $str = '';
    while (@$tokens && $tokens->[0][0] ne $expected_token){
        $str .= $tokens->[0][1];
        shift @$tokens;
    }
    p_expect($tokens, $expected_token, $meta);
    return $str;
}

sub parse_hash {
    my ($str, $statement_name, $meta) = @_;
    return unless defined $str;

    my $del_string = qr{(
         '[^'\\]*(?>\\.[^'\\]*)*'
        |"[^"\\]*(?>\\.[^"\\]*)*'
        |[^"']\S*
    )}x;
    my %options;
    pos($str) = 0;
    while ($str =~ m/\G\s*(\w+):$del_string\s*/gc){
        my $key = $1;
        my $val = $2;
        $val =~ s/^['"]//;
        $val =~ s/['"]$//;
        $val =~ s{\\(.)}{$1}g;
        $options{$key} = $val;
    }
    return %options;
    if (pos($str) + 1 < length($str)){
        # end of string not reached
        parse_error(qq{Can't parse key-value pairs in $statement_name statement. Syntax is key1:val1 key2:val2 ... },
                    $meta->{FILES});
    }
}

sub my_dclone {
    # dclone can't handle code references, which is very bad
    # becase DBI objects from App::Mowyw::Datasource::DBI hold code refs.
    # so we don't clone blessed objects at all, but pass a reference instead.
    my $meta = shift;
    my %result;
    for (keys %$meta){
        if ($_ eq 'VARS'){
            my %vs = %{$meta->{VARS}};
            for my $v (keys %vs){
                if (blessed $vs{$v}){
                    $result{VARS}{$v} = $vs{$v};
                } else {
                    $result{VARS}{$v} = ref $vs{$v} ? dclone($vs{$v}) : $vs{$v};
                }
            }
        } else {
            $result{$_} = ref $meta->{$_} ? dclone($meta->{$_}) : $meta->{$_};
        }
    }

    return \%result;
}

sub p_braces {
    my $tokens = shift;
    my $meta = shift;
    my $str = "";
    p_expect($tokens,"BRACES_START", $meta);
    if ($meta->{CURRENT_ITEM}){
#       print "using text inside braces\n";
        $str .= parse_tokens($tokens, $meta);
    } else {
        # discard the text between opening {{ and closing }} braces
#       print "discarding text inside braces\n";
        parse_tokens($tokens, $meta);
    }
    p_expect($tokens, "BRACES_END", $meta);
    return $str;
}

sub p_setvar {
    my $tokens = shift;
    my $meta = shift;
    my $str = "";
    while ($tokens->[0]->[0] ne "TAG_END"){
        $str .= $tokens->[0]->[1];
        shift @$tokens;
    }
    p_expect($tokens, "TAG_END", $meta);
    $str = strip_ws($str);
    $str =~ m#^(\S+)\s#;
    my $name = $1;
    my $value = $str;
    $value =~ s/^\S+\s+//;
    $meta->{VARS}->{$name} = $value;
    return "";
}

sub p_readvar {
    my ($tokens, $meta) = @_;
    my $str = strip_ws(slurp_upto_token($tokens, 'TAG_END', $meta));
    my ($name, $rest) = split m/\s+/, $str, 2;
    my %options = parse_hash($rest, 'readvar', $meta);
    my $c = resolve_var($name, $meta);

    if (defined $options{escape} && lc $options{escape} eq 'html'){
        return encode_entities($c);
    }
    return $c if defined $c;
    return '';
}

sub p_syntaxfile {
    my $tokens = shift;
    my $meta = shift;
    my $tag_content = shift @$tokens;
    $tag_content = strip_ws($tag_content->[1]);
    p_expect($tokens, "TAG_END", $meta);
    my @t = split m/\s+/, $tag_content;
    if (scalar @t != 2){
        parse_error(
            "Usage of syntaxfile tag: [[[syntaxfile <filename> <language>",
            $meta->{FILES},
            $tokens->[0],
        );
    }

}

sub p_syntax {
    my $tokens = shift;
    my $meta = shift;
    my $lang = shift @$tokens;
    $lang = strip_ws($lang->[1]);
    p_expect($tokens, "TAG_END", $meta);
    my $str = "";
    while ($tokens->[0] and  not ($tokens->[0]->[0] eq "TAG_START" and $tokens->[1]->[1] eq "endsyntax" and $tokens->[2]->[0] eq "TAG_END")){
        $str .= $tokens->[0]->[1];
        shift @$tokens;
    }
    p_expect($tokens, "TAG_START", $meta);
    p_expect($tokens, "KEYWORD", $meta);
    p_expect($tokens, "TAG_END", $meta);

    return do_hilight($str, $lang, $meta);
}

sub do_hilight {
    my ($str, $lang, $meta) = @_;
    if ($lang eq 'escape'){
        return encode_entities($str);
    }
    eval {
        no warnings "all";
        require Text::VimColor;
    };
    if ($@){
        # require was not successfull 
        print STDERR " Not syntax hilighting, Text::VimColor not found\n" unless $config{quiet};
        # encode at least some special chars "by hand"
        return encode_entities($str);
    } else {
        print STDERR "." unless $config{quiet};
        # any encoding will do if vim automatically detects it
        my $vim_encoding = 'utf-8';
        my $BOM = "\x{feff}";
        my $syn = Text::VimColor->new(
                filetype    => $lang,
                string      => encode($vim_encoding, $BOM . $str),
                );
        $str = decode($vim_encoding, $syn->html);
        $str =~ s/^$BOM//;
        return $str;
    }
}

# parse sub: expect a specific token, return its content or die if the
# expectation was not met.
sub p_expect {
    my ($tokens, $expect, $meta) = splice @_, 0, 3;
    parse_error("Unexpected End of File, expected $expect", $meta->{FILES}) unless (@$tokens);
    confess("\$tokens not a array ref - this is most likely a programming error\n$internal_error_message") unless(ref($tokens) eq "ARRAY");
    if ($tokens->[0]->[0] eq $expect){
        my $e_val = shift;
        if (not defined($e_val) or $e_val eq $tokens->[0]->[1]){
            my $val =  $tokens->[0]->[1];
            shift @$tokens;
            return $val;
        } else {
            parse_error("Expected '$e_val', got $tokens->[0][1]\n",
                    $meta->{FILES}, $tokens->[0]);
        }
    }
    parse_error(
        "Expected token $expect, got $tokens->[0]->[0]\n",
        $meta->{FILES},
        $tokens->[0],
    );
}


sub lex_string {
    my $text = shift;
    my @tokens = lex($text, \@input_tokens);
#   print Data::Dumper->Dump(\@tokens);
    return @tokens;
}

sub parse_tokens {
    my $tokens = shift;
    my $meta = shift;
    my $str = "";
    if ($meta->{INSIDE_ITEM}){
        $str .= p_text($tokens);
    } else {
        $str .= p_text($tokens, {BRACES_START => 1, BRACES_END => 1});
    }
    while(@$tokens 
            and $tokens->[0]->[0] ne "TAG_END" 
            and $tokens->[0]->[0] ne "BRACES_END"){
#       print scalar @$tokens;
#       print " tokens left\n";
#       warn $str;

        if ($tokens->[0]->[0] eq "TAG_START"){
            my $start = p_expect($tokens, "TAG_START", $meta);
            my $key = p_expect($tokens, 'KEYWORD', $meta);
#           warn "Found keyword $key\n";
            my $error_sub = sub {
                my ($tag, $prior_tag) = @_;
                return sub {
                    my ($tokens, $meta) = @_;
                    parse_error(
                        "Unexpected tag '$tag' without prior '$prior_tag'",
                        $meta->{FILES},
                        $tokens->[0],
                    );
                }
            };

            if ($meta->{PARSE_UPTO} && $meta->{PARSE_UPTO} eq $key){
                p_expect($tokens, 'TAG_END', $meta);
                return $str;
            }

            my %dispatch = (
                include     => \&p_include,
                system      => \&p_system,
                menu        => \&p_menu,
                item        => \&p_item,
                option      => \&p_option,
                verbatim    => \&p_verbatim,
                endverbatim => $error_sub->(qw(endverbatim verbatim)),
                bind        => \&p_bind,
                comment     => \&p_comment,
                setvar      => \&p_setvar,
                readvar     => \&p_readvar,
                syntax      => \&p_syntax,
                syntaxfile  => \&p_syntaxfile,
                endsyntax   => $error_sub->(qw(endsyntax syntax)),
                for         => \&p_for,
                endfor      => $error_sub->(qw(endfor for)),
                ifvar       => \&p_ifvar,
                endifvar    => $error_sub->(qw(endifvar ifvar)),
            );
            my $func = $dispatch{$key};
            if ($func){
                $str .= &$func($tokens, $meta);
            } else {
                confess("Action for keyword '$key' not yet implemented");
            }

        } elsif ($tokens->[0]->[0] eq "BRACES_START") {
            $str .= p_braces($tokens, $meta);
        } else {
            print "Don't know what to do with token $tokens->[0]->[0]\n";
        }
        if ($meta->{INSIDE_ITEM}){
            $str .= p_text($tokens);
        } else {
            $str .= p_text($tokens, {BRACES_START => 1, BRACES_END => 1});
        }

    }
    return $str;
}

sub parse_file {
    my ($fn, $meta) = @_;
#    print Dumper \%config;
#    print "\n$config{encoding}\n";
    open (my $fh, "<:encoding($config{encoding})", $fn) 
        or confess "Can't open file '$fn' for reading: $!";
    my $str = do { local $/; <$fh> };
#    print $str;
    parse_str($str, $meta);
}

sub parse_str {
    my ($str, $meta) = @_;
    my @tokens = lex_string($str);
#   print Data::Dumper->Dump(\@tokens);
    return parse_tokens(\@tokens, $meta);
}

sub get_meta_data {
    my $fn = shift;
    my $meta = {
        ITEMS           => [], 
        FILES           => [], 
        CURRENT_ITEM    => undef,
        OPTIONS         => {},
        VARS            => {},
    };

    my $global_include_fn = get_include_filename('include', 'global', $fn);

    if (-e $global_include_fn ){
#        warn "Reading global include file '$global_include_fn'\n";
        $meta->{FILES} = [$global_include_fn];
        # use parse_file for its side effects on meta
        my $g = parse_file($global_include_fn, $meta);
    }
    # replace call stack
    # otherwise all files seem to be included from the globl include file,
    # which is somewhat ugly
    $meta->{FILES} = [];
    return $meta;
}


sub process_file {
    my ($fn, $config) = @_;

    my $new_fn = get_online_fn($fn);

    # process file at all?
    my $process = 0;
#    use Data::Dumper;
#    print Dumper $App::Mowyw::config{file_filter};
    for my $f(@{$App::Mowyw::config{file_filter}}){
        my ($include, undef, $re) = @$f;
        if ($fn =~ m/$re/){
            $process = $include;
            last;
        }
    }

#    print +($process ? '' : 'not '), "processing file $fn\n";

    if ($process){

        if ($config{make_behaviour} and  -e $new_fn and (stat($fn))[9] < (stat($new_fn))[9]){
            return;
        }
        print STDERR "Processing File '$fn'..." unless $config{quiet};

        my $metadata = get_meta_data($fn);
        push @{$metadata->{FILES}}, $fn;
        my $str = parse_file($fn, $metadata);
#       print Data::Dumper->Dump([$metadata]);
        my $header = "";
        my $footer = "";

#       warn $str;
        unless (exists $metadata->{OPTIONS}{'no-header'}){
            my $m = my_dclone($metadata);
            my $header_fn = get_include_filename('include', 'header', $fn);
            unshift @{$m->{FILES}}, $header_fn;
            $header = parse_file($header_fn, $m);
        }
        unless (exists $metadata->{OPTIONS}{'no-footer'}){
            my $m = my_dclone($metadata);
            my $footer_fn = get_include_filename('include', 'footer', $fn);
            unshift @{$m->{FILES}}, $footer_fn;
            $footer = parse_file($footer_fn, $metadata);
        }
        my ($tmp_fh, $tmp_name) = tempfile( UNLINK => 1);
        binmode $tmp_fh, ":encoding($config{encoding})";
        print $tmp_fh $header, $str, $footer;
        close $tmp_fh;
        if (compare($new_fn, $tmp_name) == 0){
            print STDERR " not changed\n" unless $config{quiet};
        } else {
            copy($tmp_name, $new_fn);
            print STDERR " done\n" unless $config{quiet};
        }
    } else {
        if (compare($fn, $new_fn) == 0){
            # do nothing
        } else {
            copy($fn, $new_fn);
            print "Updated file $new_fn (not processed)\n";
        }
    }
}


sub get_online_fn {
    my $fn = shift;
    my $new_fn = $fn;
    $new_fn =~ s{^$config{default}{source}}{};
    {
        my $found = 0;
        for ( keys %{$config{per_fn}} ){
            if ( $new_fn =~ m/$_/ ){
                $found = 1;
                $new_fn = $config{per_fn}{$_}{online} . $new_fn;
                last
            }
        }
        if ($found == 0){
            $new_fn = $config{default}{online} . $new_fn;
        }
    }
    return $new_fn;

}

sub get_config {
    my $cfg_file = 'mowyw.conf';
    if (-e $cfg_file) {
        my $conf_hash = read_config_file($cfg_file); 
#       print Dumper $conf_hash;
        return transform_conf_hash($conf_hash);
    } else {
        print "No config file '$cfg_file'\n";
        return {};
    }
}

sub transform_conf_hash {
    my ($h) = @_;
    my %nh;
#   no warnings 'uninitialized';
    my %d = %{$config{default}};
    for (keys %{$h->{MATCH}}){
        my $key = $h->{MATCH}{$_};
        for my $feat (qw(include menu postfix online)){
            $nh{$key}{$feat} = 
                defined $h->{ uc $feat }{$_} ?  $h->{ uc $feat }{$_} : $d{$feat};
        }
    }
    my @filter;
    {
        my %inc = %{$h->{INCLUDE}};
        %inc = ( 50 => '\..?htm') unless keys %inc;
        my %exc = %{$h->{EXCLUDE} || {}};
        while (my ($k, $v) = each %inc){
            $k =~ tr/0-9//cd;
            my $re = eval { qr{$v} } || die "Invalid regex '$v' in config: $@";
            push @filter, [1, $k, $re];
        }
        while (my ($k, $v) = each %exc){
            $k =~ tr/0-9//cd;
            my $re = eval { qr{$v} } || die "Invalid regex '$v' in config: $@";
            push @filter, [0, $k, $re];
        }
        @filter = reverse sort { $a->[1] <=> $b->[1] } @filter;
    }
#    print Dumper \%nh, \@filter;
    return (\%nh, \@filter);
}


sub get_include_filename {
    my ($type, $base_fn, $source_fn) = @_;
    confess "Usage: get_include_filename(\$type, \$base, \$source)" unless $source_fn;
#    print "Passed options ('$type', '$base_fn', '$source_fn')\n";
    # $type should be one of qw(include menu online)
    my $re;
#    print Dumper $config{per_fn};
    for (keys %{$config{per_fn}}){
        if ($source_fn =~ m/$_/){
            $re = $_;
#            warn "Found regex '$re'";
            last;
        }
    }
    my $prefix  = $config{default}{$type};
    my $postfix = $config{default}{postfix};
    if (defined $re){
        $prefix  = $config{per_fn}{$re}{$type}   if defined $config{per_fn}{$re}{$type};
        $postfix = $config{per_fn}{$re}{postfix} if defined $config{per_fn}{$re}{postfix};
    }

    return $prefix . $base_fn . $postfix;
}
1;
