package Beagle::Util;

use warnings;
use strict;
use Beagle::Helper;
use base 'Exporter';
use Config::INI::Reader;
use Config::INI::Writer;
use Any::Moose 'Util::TypeConstraints';
use Lingua::EN::Inflect 'PL';

# to handle checkbox input.
coerce 'Bool' => from 'Ref' => via { 1 };

enum 'BeagleBackendType' => [qw/git fs/];
enum 'BeagleFormat'      => [qw/plain markdown wiki pod html/];
enum 'BeagleLayout'      => [qw/blog plain/];
enum 'BeagleTheme'       => [qw/orange blue dark/];

our %ABBREV = map { $_ => 1 } qw/isbn/;

our (
    $ROOT,               $KENNEL,         $CACHE,
    $DEVEL,              %SHARE_ROOT,     @SPREAD_TEMPLATE_ROOTS,
    @WEB_TEMPLATE_ROOTS, $RELATION_PATH, $MARKS_PATH,
    $CACHE_ROOT, $BACKENDS_ROOT, $WEB_OPTIONS, $WEB_ALL,
    @PLUGINS, $SEARCHED_PLUGINS, @PO_ROOTS, $HANDLES,
    @WEB_NAMES, $SEARCHED_WEB_NAMES, $WEB_ADMIN, @SYSTEM_ROOTS,
    $CURRENT_USER,
);

BEGIN {

# I got error: "Goto undefined subroutine &die" on windows strawberry 5.12.2
# &CORE::die doesn't help

    *CORE::GLOBAL::die = sub {
#        goto &die unless ( caller() )[0] =~ /^Beagle::/;
        return die @_ unless ( caller() )[0] =~ /^Beagle::/;

        @_ = map { encode( locale => $_ ) } @_;
        return confess @_ if enabled_devel();

        # we want to show user the line info if there is nothing to print
        push @_, newline() if @_;

        @_ = grep { defined } @_;
        die @_;
    };

    *CORE::GLOBAL::warn = sub {
# interesting, I get warn if use goto &warn:
# Goto undefined subroutine &Beagle::Util::warn
#       goto &warn unless (caller())[0] =~ /^Beagle::/;
        return warn @_ unless ( caller() )[0] =~ /^Beagle::/;

        @_ = grep { defined } @_;

        # we want to show user the line info if there is nothing to print
        push @_, newline() if @_;
        @_ = map { encode( locale => $_ ) } @_;
        warn @_;
    };
}

our @EXPORT = (
    @Beagle::Helper::EXPORT, qw/
      enabled_devel enable_devel disable_devel enabled_cache enable_cache disable_cache
      set_current_root current_root root_name set_current_root_by_name check_root
      static_root kennel user_alias roots set_roots
      core_config set_core_config set_user_alias relation set_relation
      default_format split_id root_name name_root root_type
      system_alias create_backend alias aliases resolve_id die_entry_not_found
      die_entry_ambiguous current_handle handles resolve_entry
      is_in_range parse_wiki  parse_markdown parse_pod
      whitelist set_whitelist
      detect_roots backends_root cache_root
      share_root marks set_marks
      spread_template_roots web_template_roots
      entry_type_info entry_types
      relation_path marks_path
      web_options tweak_name plugins po_roots
      web_all web_names web_admin
      system_roots current_user
      /
);

$DEVEL =
  defined $ENV{BEAGLE_DEVEL} && length $ENV{BEAGLE_DEVEL}
  ? ( $ENV{BEAGLE_DEVEL} ? 1 : 0 )
  : ( exists core_config()->{devel} ? core_config()->{devel} : 1 );

sub enabled_devel {
    return $DEVEL ? 1 : 0;
}

sub enable_devel {
    $DEVEL = 1;
}

sub disable_devel {
    undef $DEVEL;
    return 1;
}

$CACHE =
  defined $ENV{BEAGLE_CACHE} && length $ENV{BEAGLE_CACHE}
  ? ( $ENV{BEAGLE_CACHE} ? 1 : 0 )
  : ( exists core_config()->{cache} ? core_config()->{cache} : 1 );

sub enabled_cache {
    return $CACHE ? 1 : 0;
}

sub enable_cache {
    $CACHE = 1;
}

sub disable_cache {
    undef $CACHE;
    return 1;
}

sub spread_template_roots {
    return @SPREAD_TEMPLATE_ROOTS if @SPREAD_TEMPLATE_ROOTS;
    @SPREAD_TEMPLATE_ROOTS = ();

    if ( $ENV{BEAGLE_SPREAD_TEMPLATE_ROOTS} ) {
        push @SPREAD_TEMPLATE_ROOTS, split /\s*,\s*/,
          decode( locale => $ENV{BEAGLE_SPREAD_TEMPLATE_ROOTS} );
    }

    if ( core_config()->{spread_template_roots} ) {
        push @SPREAD_TEMPLATE_ROOTS, split /\s*,\s*/,
          core_config()->{spread_template_roots};
    }

    for my $plugin ( reverse plugins() ) {
        if ( try_load_class($plugin) ) {
            my $root = catdir( share_root($plugin), 'spread_templates' );
            if ( -e $root ) {
                push @SPREAD_TEMPLATE_ROOTS, $root;
            }
        }
    }

    push @SPREAD_TEMPLATE_ROOTS, catdir( share_root(), 'spread_templates' );
    @SPREAD_TEMPLATE_ROOTS = uniq @SPREAD_TEMPLATE_ROOTS;
    return @SPREAD_TEMPLATE_ROOTS;
}

sub web_template_roots {
    return @WEB_TEMPLATE_ROOTS if @WEB_TEMPLATE_ROOTS;
    @WEB_TEMPLATE_ROOTS = ();
    if ( $ENV{BEAGLE_WEB_TEMPLATE_ROOTS} ) {
        push @WEB_TEMPLATE_ROOTS, split /\s*,\s*/,
          decode( locale(), $ENV{BEAGLE_WEB_TEMPLATE_ROOTS} );
    }

    if ( core_config()->{web_template_roots} ) {
        push @WEB_TEMPLATE_ROOTS, split /\s*,\s*/,
          core_config()->{web_template_roots};
    }

    for my $plugin ( reverse plugins() ) {
        if ( try_load_class($plugin) ) {
            my $root = catdir( share_root($plugin), 'views' );
            if ( -e $root ) {
                push @WEB_TEMPLATE_ROOTS, $root;
            }
        }
    }

    push @WEB_TEMPLATE_ROOTS, catdir( share_root(), 'views' );
    @WEB_TEMPLATE_ROOTS = uniq @WEB_TEMPLATE_ROOTS;
    return @WEB_TEMPLATE_ROOTS;
}

sub po_roots {
    return @PO_ROOTS if @PO_ROOTS;
    push @PO_ROOTS, catdir( share_root(), 'po' );

    for my $plugin ( plugins() ) {
        if ( try_load_class($plugin) ) {
            my $root = catdir( share_root($plugin), 'po' );
            if ( -e $root ) {
                push @PO_ROOTS, $root;
            }
        }
    }

    if ( core_config()->{po_roots} ) {
        push @PO_ROOTS, split /\s*,\s*/,
          core_config()->{po_roots};
    }

    if ( $ENV{BEAGLE_PO_ROOTS} ) {
        push @PO_ROOTS, split /\s*,\s*/,
          decode( locale(), $ENV{BEAGLE_PO_ROOTS} );
    }

    @PO_ROOTS = uniq @PO_ROOTS;
    return @PO_ROOTS;
}

sub set_current_root {
    my $dir;
    if (@_) {
        $dir = shift;
        die "set_current_root is called with an undef value"
          unless defined $dir;
    }
    else {
        $dir = decode( locale => $ENV{BEAGLE_ROOT} || '' );

        if ( !$dir && length $ENV{BEAGLE_NAME} ) {
            my $roots = roots();
            my $b = $roots->{ decode( locale => $ENV{BEAGLE_NAME} ) };
            $dir = $b->{local} if $b && $b->{local};
        }

        $dir ||= core_config()->{default_root};

        if ( !$dir && length core_config()->{default_name} ) {
            my $roots = roots();
            my $b     = $roots->{ core_config()->{default_name} };
            $dir = $b->{local} if $b && $b->{local};
        }
    }

    die
"couldn't find backend root, please specify env BEAGLE_NAME or BEAGLE_ROOT"
      unless $dir;

    $dir = rel2abs($dir);

    if ( check_root($dir) ) {
        return $ROOT = $dir;
    }
    else {
        die "$dir is invalid backend root";
    }
}

sub current_root {
    return $ROOT if defined $ROOT;

    my $not_die = shift;
    eval { set_current_root() };
    if ( $@ && !$not_die ) {
        die $@;
    }
    return $ROOT if $ROOT;
    return;
}

sub set_current_root_by_name {
    my $name = shift or die 'need name';

    return set_current_root( name_root($name) );
}

sub check_root {
    my $dir = encode( locale_fs => $_[-1] );
    return unless $dir && -d $dir;
    my $info = catfile( $dir, 'info' );
    if ( -e $info ) {
        open my $fh, '<', $info or die $!;
        local $/;
        my $content = <$fh>;
        if ( $content && $content =~ /id:/ ) {
            return 1;
        }
    }
    return;
}

sub static_root {
    my $handle = shift;
    return catdir( ( $handle ? $handle->root : current_root() ),
        'attachments' );
}

sub kennel {
    return $KENNEL if $KENNEL;
    if ( $ENV{BEAGLE_KENNEL} ) {
        $KENNEL = decode( locale => $ENV{BEAGLE_KENNEL} );
    }
    else {
        $KENNEL = catdir( user_home, '.beagle' );
    }
    return $KENNEL;
}

sub cache_root {
    return $CACHE_ROOT if $CACHE_ROOT;
    if ( $ENV{BEAGLE_CACHE_ROOT} ) {
        $CACHE_ROOT = decode( locale => $ENV{BEAGLE_CACHE_ROOT} );
    }
    else {
        $CACHE_ROOT = core_config()->{cache_root}
          || catfile( kennel(), 'cache' );
    }
    return $CACHE_ROOT;
}

sub backends_root {
    return $BACKENDS_ROOT if $BACKENDS_ROOT;
    if ( $ENV{BEAGLE_BACKENDS_ROOT} ) {
        $BACKENDS_ROOT = decode( locale => $ENV{BEAGLE_BACKENDS_ROOT} );
    }
    else {
        $BACKENDS_ROOT = core_config()->{backends_root}
          || catfile( kennel(), 'roots' );
    }
    return $BACKENDS_ROOT;
}

my $config;

sub config {
    my $section = shift;
    my $config_file = catfile( kennel(), 'config' );
    if ( -e $config_file ) {
        open my $fh, '<:encoding(utf8)', $config_file or die $!;
        $config ||= Config::INI::Reader->read_handle($fh);
    }
    return {} unless $config;

    my $ret = $section ? $config->{$section} : $config;
    return dclone($ret);
}

sub set_config {
    my $value   = shift;
    my $section = shift;

    my $config;
    if ($section) {
        $config = config();
        $config->{$section} = $value;
    }
    else {
        $config = $value;
    }

    my $input = Config::INI::Writer->preprocess_input($config);
    eval { Config::INI::Writer->validate_input( $input ) };
    die $@ if $@;

    my $config_file = catfile( kennel(), 'config' );
    my $parent = encode( locale_fs => parent_dir($config_file) );
    make_path( parent_dir($config_file) ) or die $! unless -e $parent;
    open my $fh, '>:encoding(utf8)', $config_file or die $!;

    return Config::INI::Writer->write_handle( $config, $fh );
}

sub core_config { exists config()->{'core'} ? config()->{'core'} : {} }
sub user_alias  { exists config()->{alias}  ? config()->{alias}  : {} }
sub set_core_config { set_config( @_, 'core' ) }
sub set_user_alias  { set_config( @_, 'alias' ) }

sub whitelist {
    my $file = catfile( kennel(), 'whitelist' );
    return [] unless -e $file;
    return [ map { /(\S.*\S)/ ? $1 : () } read_file($file) ];
}

sub set_whitelist {
    my $value = @_ > 1 ? [@_] : shift;
    my $file = encode( locale_fs => catfile( kennel(), 'whitelist' ) );
    my $parent = parent_dir($file);
    make_path( parent_dir($file) ) or die $! unless -e $parent;

    write_file( $file,
        ref $value eq 'ARRAY' ? ( join newline, @$value ) : $value );
}

sub roots {
    my $config = config();
    my %roots;
    for my $section ( keys %$config ) {
        if ( $section =~ m{^roots/(.*\S)} ) {
            $roots{$1} = $config->{$section};
        }
    }
    return \%roots;
}

sub set_roots {
    my $all = shift or die;
    $config = config();
    for my $section ( keys %$config ) {
        if ( $section =~ m{^roots/(.*\S)} ) {
            delete $config->{$section};
        }
    }

    for my $name ( keys %$all ) {
        $config->{"roots/$name"} = $all->{$name};
    }
    set_config($config);
}

sub relation_path {
    return $RELATION_PATH if defined $RELATION_PATH;

    if ( $ENV{BEAGLE_RELATION_PATH} ) {
        $RELATION_PATH = decode( locale => $ENV{BEAGLE_RELATION_PATH} );
    }
    else {
        $RELATION_PATH = core_config()->{relation_path}
          || catfile( kennel(), '.relation' );
    }
    return $RELATION_PATH;
}

sub relation {
    my $file = relation_path();
    if ( -e $file ) {
        return retrieve($file);
    }
    else {
        return {};
    }
}

sub set_relation {
    my $map = shift or return;
    nstore( $map, relation_path() );
}

sub marks_path {
    return $MARKS_PATH if defined $MARKS_PATH;

    if ( $ENV{BEAGLE_MARKS_PATH} ) {
        $MARKS_PATH = decode( locale => $ENV{BEAGLE_MARKS_PATH} );
    }
    else {
        $MARKS_PATH = core_config()->{marks_path}
          || catfile( kennel(), '.marks' );
    }
    return $MARKS_PATH;
}

sub marks {
    my $file = marks_path();
    if ( -e $file ) {
        return retrieve($file);
    }
    else {
        return {};
    }
}

sub set_marks {
    my $marks = shift or return;
    nstore( $marks, marks_path() );
}

sub default_format {
    return
         $ENV{BEAGLE_DEFAULT_FORMAT}
      || core_config()->{default_format}
      || 'plain';
}

sub split_id {
    my $id = $_[-1];
    if ( $id && $id =~ m{^(\w{2})(\w{30})$} ) {
        return ( $1, $2 );
    }
    return $id;
}

my %root_name;
my %name_root;

sub root_name {
    my $root = shift || current_root('not die');
    return 'global' unless defined $root;

    return $root_name{$root} if $root_name{$root};

    my $roots = roots();
    for my $name ( keys %$roots ) {
        if ( $root eq $roots->{$name}{local} ) {
            $root_name{$root} = $name;
            last;
        }
    }
    $name_root{ $root_name{$root} } ||= $root if $root_name{$root};

    $root_name{$root} ||= tweak_name( $root );
    return $root_name{$root};
}

sub tweak_name {
    my $name = shift;
    return unless defined $name;
    $name =~ s!:!_!g if is_windows;
    return $name;
}

sub name_root {
    my $name = shift;
    return $name_root{$name} if $name_root{$name};

    my $roots = roots();

    my $root = $roots->{$name} ? $roots->{$name}{local} : ();

    if ($root) {
        $name_root{$name} = $root;
        $root_name{$root} ||= $name;
        return $name_root{$name};
    }

    return;
}

my %root_type;

sub root_type {
    my $root = shift;
    return $root_type{$root} if $root_type{$root};

    my $roots = roots();
    for my $name ( keys %$roots ) {
        if ( $root eq $roots->{$name}{local} ) {
            $root_type{$root} = $roots->{$name}{type};
            last;
        }
    }

    $root_type{$root} ||=
      -e encode( locale_fs => catdir( $root, '.git' ) ) ? 'git' : 'fs';
    return $root_type{$root};
}

my $entry_type_info;

sub entry_type_info {
    return dclone($entry_type_info) if $entry_type_info;

    require Module::Pluggable::Object;
    my $models =
    Module::Pluggable::Object->new(
        search_path => [ 'Beagle::Model', map { $_ .'::Model' } plugins() ] );
    my @models = $models->plugins;
    for my $m (@models) {
        load_class($m);
        next if $m =~ /^Beagle::Model::(?:Info|Attachment|Entry)$/;
        next unless $m =~ /::Model::(\w+)$/;
        my $type = lc $1;
        if (   $entry_type_info->{$type}
            && $entry_type_info->{$type}{class} ne $m )
        {
            warn
"conflict found for $type: $m will overrite $entry_type_info->{$type}{class}";
        }
        $entry_type_info->{$type} = { plural => PL($type), class => $m };
    }
    return $entry_type_info;
}

sub entry_types {
    return [ keys %{ entry_type_info() } ];
}

my $system_alias;

sub system_alias {
    return dclone($system_alias) if $system_alias;
    $system_alias = {
        delete    => q{rm},
        edit      => q{update},
        search    => q{ls},
        list      => q{ls},
        move      => q{mv},
        today     => q{ls --updated-after today},
        yesterday => q{ls --updated-after 'yesterday'},
        month     => q{ls --updated-after 'this month'},
        thismonth => q{ls --updated-after 'this month'},
        year      => q{ls --updated-after 'this year'},
        thisyear  => q{ls --updated-after 'this year'},
        lastmonth => q{ls --updated-after 'last month'},
        lastyear  => q{ls --updated-after 'last year'},
        finals    => q{ls --final},
        drafts    => q{ls --draft},
        push      => q{git push},
        pull      => q{git pull},
    };

    my $type_info = entry_type_info();
    for my $type ( keys %$type_info ) {
        unless ( load_optional_class("Beagle::Cmd::Command::$type") ) {
            $system_alias->{$type} = "create --type $type";
        }

        my $pl = $type_info->{$type}{plural};
        unless ( load_optional_class("Beagle::Cmd::Command::$pl") ) {
            $system_alias->{$pl} = "ls --type $type";
        }
    }
    return dclone($system_alias);
}

sub create_backend {
    my %opt  = @_;
    my $root = $opt{root} or die "need root";
    my $type = $opt{type} || 'git';

    $opt{'name'}  ||= core_config()->{user_name};
    $opt{'email'} ||= core_config()->{user_email};

    my $sub = '_create_backend_' . lc $type;
    {
        no strict 'refs';
        return $sub->(%opt);
    }
}

sub _create_backend_fs {
    my %opt  = @_;
    my $root = $opt{root};

    my $name  = $opt{'name'};
    my $email = $opt{'email'};

    require Beagle::Model::Info;
    my $info = $opt{'info'} || Beagle::Model::Info->new(
        ( $name  ? ( name  => $name )  : () ),
        ( $email ? ( email => $email ) : () ),
        root => '',
    );
    write_file( encode( locale_fs => catfile( $root, 'info' ) ), $info->serialize )
      or die $!;

    return 1;
}

sub _create_backend_git {
    my %opt  = @_;
    my $root = $opt{root};

    my $git;
    require Beagle::Wrapper::git;
    if ( $opt{bare} ) {
        my $remote = Beagle::Wrapper::git->new( root => $root );
        $remote->init('--bare');

        require File::Temp;
        my $tmp_root = File::Temp::tempdir( CLEANUP => 1 );
        $git = Beagle::Wrapper::git->new();
        $git->clone( $root, catdir( $tmp_root, 'tmp' ) );
        $git->root( catdir( $tmp_root, 'tmp' ) );
    }
    else {
        $git = Beagle::Wrapper::git->new( root => $root );
        $git->init();
    }

    my $name  = $opt{'name'};
    my $email = $opt{'email'};

    if ($name) {
        $git->config( '--add', 'user.name', $name );
    }

    if ($email) {
        $git->config( '--add', 'user.email', $email );
    }

    _create_backend_fs( %opt, root => $git->root );

    $git->add('.');
    $git->commit( '-m' => "init beagle $name" );

    if ( $opt{bare} ) {
        $git->push( 'origin', 'master' );
    }
    return 1;
}

sub alias {
    return { %{ system_alias() }, %{ user_alias() } };
}

sub aliases {
    return keys %{ alias() };
}

sub resolve_entry {
    my $str = shift or return;
    return resolve_id( $str, @_ ) if $str =~ /^[a-z0-9]+$/;
    return unless $str =~ s/^://;

    my %opt = ( handle => undef, @_ );

    require Beagle::Handle;
    my @bh;
    if ( $opt{handle} ) {
        push @bh, $opt{handle};
    }
    else {
        my $all = roots();
        @bh = map { Beagle::Handle->new( root => $all->{$_}{local} ) }
          keys %{$all};
    }

    my @found;
    for my $bh (@bh) {
        for my $entry ( @{ $bh->entries } ) {
            if ( $entry->serialize( id => 1 ) =~ qr/$str/im ) {
                push @found,
                  { id => $entry->id, entry => $entry, handle => $bh };
            }
        }
    }
    return @found;
}

sub die_not_found {
    my $str = shift;
    die "no such entry match $str";
}

sub resolve_id {
    my $i = shift or return;
    my %opt = ( handle => undef, @_ );
    my $bh = $opt{'handle'};

    require Beagle::Handle;
    if ($bh) {
        my @ids = grep { /^$i/ } keys %{ $bh->map };
        return
          map { { id => $_, entry => $bh->map->{$_}, handle => $bh } } @ids;
    }
    else {
        my $relation = relation;
        my @ids = grep { /^$i/ } keys %$relation;
        my @ret;
        for my $i (@ids) {
            my $root = name_root( $relation->{$i} );
            my $bh = Beagle::Handle->new( root => $root );
            push @ret, { id => $i, entry => $bh->map->{$i}, handle => $bh };
        }
        return @ret;
    }
}

sub die_entry_not_found {
    my $i = shift;
    die "no such entry matching $i";
}

sub die_entry_ambiguous {
    my $i     = shift;
    my @items = @_;
    my @out   = "ambiguous '$i':";
    for my $item (@items) {
        push @out, join( ' ', $item->{id}, $item->{entry}->summary(10) );
    }
    die join newline(), @out;
}

sub current_handle {
    my $root = current_root('not die');
    require Beagle::Handle;

    if ($root) {
        return Beagle::Handle->new( root => $root, @_ );
    }
    return;
}

sub handles {
    return $HANDLES if $HANDLES;
    my $all = roots();
    require Beagle::Handle;
    $HANDLES = {
        map { $_ => Beagle::Handle->new( root => $all->{$_}{local} ) }
          keys %$all
    };
    return $HANDLES;
}

sub is_in_range {
    my ( $entry, %limit ) = @_;

    my $created = $entry->created;
    my $updated = $entry->updated;

    # if on the exact epoch, before doesn't include the point, after does
    return if $limit{'created_before'} && $created >= $limit{'created_before'};
    return if $limit{'created_after'}  && $created < $limit{'created_after'};
    return if $limit{'updated_before'} && $updated >= $limit{'updated_before'};
    return if $limit{'updated_after'}  && $updated < $limit{'updated_after'};
    return 1;
}

my $whitelist = whitelist() || [];

use HTML::Defang;
my $defang = HTML::Defang->new(
    fix_mismatched_tags => 1,
    url_callback        => sub {
        my ( $self, $defang, $tag, $key, $val ) = @_;
        if ( $tag eq 'a' && $key eq 'href' && $$val && $$val =~ /^http/ ) {
            require URI;
            my $uri  = URI->new($$val);
            my $host = $uri->host;
            for my $safe (@$whitelist) {
                if ( $host =~ m{(?:^|\.)\Q$safe\E$} ) {
                    return HTML::Defang::DEFANG_NONE;
                }
            }
        }
        return HTML::Defang::DEFANG_DEFAULT;
    },
);

sub defang {
    my $html = $_[-1] or return '';
    return $defang->defang($html);
}

sub parse_wiki {
    my $value = shift;
    my $trust = shift;
    return '' unless defined $value;

    if ( !$INC{'Text/WikiFormat.pm'} ) {
        require Text::WikiFormat;
        {
            no warnings 'redefine';
            *Text::WikiFormat::escape_link = sub {
                my ( $link, $opts ) = @_;

                my $u = URI->new($link);
                return $link if $u->scheme();

                # it's a relative link
                # if not hack this, / will be escaped to %2f, which is bad
                my $unsafe_chars = '^A-Za-z0-9\-\._~/';
                return ( URI::Escape::uri_escape( $link, $unsafe_chars ), 1 );
            };
        }
        Text::WikiFormat->import(
            as       => '_parse_wiki',
            extended => 1,
            indented => {
                map { $_ => ( $_ eq 'annotation' ? 0 : 1 ) }
                  qw/ ordered unordered code shell annotation /
            },
            code  => [ qq{<pre class="prettyprint">\n}, "</pre>\n", '', "\n" ],
            shell => [ qq{<pre class="shell">\n},       "</pre>\n", '', "\n" ],
            annotation =>
              [ qq{<div class="annotation">}, "</div>\n", '', "\n" ],
            blocks => {
                code       => qr/^:(?=\s)/,
                shell      => qr/^\$(?=\s)/,
                annotation => qr{^\@(?=\s)},
            },
            paragraph  => [ '<p>', "</p>\n", '', '', 1 ],
            blockorder => [
                qw/ header line ordered unordered code shell annotation paragraph /
            ],
            extended_link_delimiters => [ '[[', ']]' ],
            implicit_links           => 0,
        );
    }

    my $ret = _parse_wiki($value);
    return $ret if $trust;
    return defang($ret);
}

sub parse_markdown {
    my $value = shift;
    my $trust = shift;
    return '' unless defined $value;

    require Text::MultiMarkdown;
    my @lines = split /\r?\n/, $value;
    my $block_name;
    my $code = '';
    my @new;
    for (@lines) {
        if ($block_name) {
            my $gard =
                $block_name eq 'shell'       ? '$'
              : $block_name eq 'prettyprint' ? ':'
              :                                '@';
            if (/^\s+\Q$gard\E\s+(.*)/m) {
                $code .= $1 ? ( encode_entities($1 . "\n") ) : "\n";
            }
            else {
                if ( $block_name eq 'annotation' ) {
                    push @new, qq{<div class="$block_name">$code</div>};
                }
                else {
                    push @new, qq{<pre class="$block_name">$code</pre>};
                }
                undef $block_name;
                $code = '';
                push @new, $_;
            }
        }
        else {
            if (/^\s+([\$:@])\s+(.*)/m) {
                $block_name =
                    $1 eq '$' ? 'shell'
                  : $1 eq ':' ? 'prettyprint'
                  :             'annotation';
                $code = encode_entities($2 . "\n");
            }
            else {
                push @new, $_;
            }
        }
    }

    if ($block_name) {
        push @new, qq{<pre class="$block_name">$code</pre>};
    }
    my $ret = Text::MultiMarkdown::markdown( join "\n", @new );
    return $ret if $trust;
    return defang( $ret );
}

sub parse_pod {
    my $value = shift;
    my $trust = shift;
    return '' unless defined $value;

    require Pod::Simple::XHTML;
    my $pod = Pod::Simple::XHTML->new;
    $pod->html_header('');
    $pod->html_footer('');
    $pod->html_h_level( $ENV{BEAGLE_POD_HTML_H_LEVEL}
          || core_config->{pod_html_h_level}
          || 3 );
    my $ret;

    $pod->output_string(\$ret);
    $pod->parse_string_document($value);

    return $ret if $trust;
    return defang( $ret );
}

sub detect_roots {
    my $base = shift || backends_root();
    return {} unless -d $base;
    my $info = {};

    opendir my $dh, $base or die $!;
    while ( my $dir = readdir $dh ) {
        next if $dir eq '.' || $dir eq '..';
        if ( check_root( decode( locale_fs => catdir( $base, $dir ) ) ) ) {

            if ( -e catdir( $base, $dir, '.git' ) ) {
                require Beagle::Wrapper::git;
                my $git =
                  Beagle::Wrapper::git->new( root => catdir( $base, $dir ) );
                my $url = $git->config( '--get', 'remote.origin.url' );
                chomp $url;
                $info->{ decode( locale_fs => $dir ) } = {
                    remote => $url,
                    local  => catdir( $base, $dir ),
                    type   => 'git',
                    trust  => 0,
                };
            }
            else {
                $info->{ decode( locale_fs => $dir ) } = {
                    local => catdir( $base, $dir ),
                    type  => 'fs',
                    trust => 0,
                };
            }
        }
        else {
            %$info = ( %$info, %{ detect_roots( catdir( $base, $dir ) ) } );
        }
    }
    return $info;
}

sub share_root {
    my $module = shift || 'Beagle';
    return $SHARE_ROOT{$module} if $SHARE_ROOT{$module};

    load_class($module);
    if ( $module eq 'Beagle' ) {
        if ( $ENV{BEAGLE_SHARE_ROOT} ) {
            $SHARE_ROOT{$module} =
              rel2abs( decode( locale => $ENV{BEAGLE_SHARE_ROOT} ) );
        }
        elsif ( core_config()->{share_root} ) {
            $SHARE_ROOT{Beagle} = rel2abs( core_config()->{share_root} );
        }
        return $SHARE_ROOT{$module} if $SHARE_ROOT{$module};
    }
    my $name  = $module;
    my $depth = $name =~ s!::!/!g;
    $name .= '.pm';
    my $path = $INC{$name};
    do { $path = parent_dir($path) } while $depth--;

    my @root = splitdir( rel2abs($path) );

    if (   $root[-2] ne 'blib'
        && $root[-1] eq 'lib'
        && ( $^O !~ /MSWin/ || $root[-2] ne 'site' ) )
    {

        # so it's -Ilib in the Beagle's source dir
        $root[-1] = 'share';
    }
    else {
        my $file = $module;
        $file =~ s!::!-!g;
        push @root, qw/auto share dist/, $file;
    }
    $SHARE_ROOT{$module} = catdir(@root);
}

sub web_options {
    return @$WEB_OPTIONS if $WEB_OPTIONS;
    require Text::ParseWords;
    my $value =
      defined $ENV{BEAGLE_WEB_OPTIONS}
      ? $ENV{BEAGLE_WEB_OPTIONS}
      : core_config()->{web_options};

    if ( defined $value ) {
        $WEB_OPTIONS = [ Text::ParseWords::shellwords($value) ];
    }
    else {
        $WEB_OPTIONS = [];
    }
    return @$WEB_OPTIONS;
}

sub web_all {
    return $WEB_ALL if defined $WEB_ALL;
    $WEB_ALL =
        defined $ENV{BEAGLE_WEB_ALL}     ? $ENV{BEAGLE_WEB_ALL}
      : defined core_config()->{web_all} ? core_config()->{web_all}
      :                                    0;

    return $WEB_ALL;
}

sub web_admin {
    return $WEB_ADMIN if defined $WEB_ADMIN;
    $WEB_ADMIN =
        defined $ENV{BEAGLE_WEB_ADMIN}     ? $ENV{BEAGLE_WEB_ADMIN}
      : defined core_config()->{web_admin} ? core_config()->{web_admin}
      :                                      0;

    return $WEB_ADMIN;
}

sub web_names {
    return @WEB_NAMES if $SEARCHED_WEB_NAMES;
    if ( $ENV{BEAGLE_WEB_NAMES} ) {
        @WEB_NAMES = split /\s*,\s*/,
          decode( locale => $ENV{BEAGLE_WEB_NAMES} );
    }
    elsif ( core_config()->{web_names} ) {
        @WEB_NAMES = split /\s*,\s*/, core_config->{web_names};
    }

    $SEARCHED_WEB_NAMES = 1;
    return @WEB_NAMES;
}

sub plugins {
    return @PLUGINS if $SEARCHED_PLUGINS;
    @PLUGINS = ();
    if ( $ENV{BEAGLE_PLUGINS} ) {
        push @PLUGINS, split /\s*,\s*/,
          decode( locale => $ENV{BEAGLE_PLUGINS} );
    }

    if ( core_config()->{plugins} ) {
        push @PLUGINS, split /\s*,\s*/,
          core_config()->{plugins};
    }
    $SEARCHED_PLUGINS = 1;

    @PLUGINS = uniq
      map { /^Beagle::Plugin::/ ? $_ : "Beagle::Plugin::$_" }
      grep { $_ } @PLUGINS;

    undef $entry_type_info;
    return @PLUGINS;
}

sub system_roots {
    return @SYSTEM_ROOTS if @SYSTEM_ROOTS;
    for my $plugin ( reverse plugins() ) {
        my $root = catdir( share_root($plugin), 'public' );
        next unless -e $root;
        push @SYSTEM_ROOTS, $root;
    }
    push @SYSTEM_ROOTS, catdir( share_root(), 'public' );
    return @SYSTEM_ROOTS;
}

sub current_user {
    return $CURRENT_USER if $CURRENT_USER;
    return $CURRENT_USER =
      Email::Address->new( core_config->{user_name},
        core_config->{user_email} )->format || '';
}

1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

