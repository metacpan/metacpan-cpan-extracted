package App::CatalystStarter::Bloated;

use v5.10.1;

use utf8::all;
use warnings;
use strict;
use autodie;
use Carp;

use version; our $VERSION = qv('0.9.3');

use File::Which qw(which);
use Path::Tiny qw(path cwd);
use Capture::Tiny qw(capture_stdout capture);
use DBI;

use List::Util qw/first/;
use List::MoreUtils qw/all/;

use Log::Log4perl qw/:easy/;

use App::CatalystStarter::Bloated::Initializr;

my $cat_dir;
my $logger = get_logger;
App::CatalystStarter::Bloated::Initializr::_set_logger($logger);
sub l{$logger}

sub import {

    shift;
    if (defined $_[0] and $_[0] eq ":test") {
        Log::Log4perl->easy_init($FATAL);
    }
    elsif ($ARGV{'--debug'}) {
        Log::Log4perl->easy_init($DEBUG);
    }
    else {
        Log::Log4perl->easy_init($INFO);
    }

    l->debug( "Log level set to DEBUG" );

}

## related test files are listed at the closing } of each sub

## a helper for easy access to paths
sub _catalyst_path {
    my $what = shift;
    my @extra;
    if ( $what eq "C" ) {
        @extra = ("lib", $ARGV{"--name"}, "Controller");
    }
    elsif ( $what eq "M" ) {
        @extra = ("lib", $ARGV{"--name"}, "Model");
    }
    elsif ( $what eq "V" ) {
        @extra = ("lib", $ARGV{"--name"}, "View");
    }
    elsif ( $what eq "TT" ) {
        @extra = ("lib", $ARGV{"--name"}, "View", $ARGV{"--TT"}.".pm");
        @_ = ();
    }
    elsif ( $what eq "JSON" ) {
        @extra = ("lib", $ARGV{"--name"}, "View", $ARGV{"--JSON"}.".pm");
        @_ = ();
    }
    else {
        @extra = ($what);
    }
    return path($cat_dir,@extra,@_)->absolute;
} ## catalyst_path.t
sub _set_cat_dir {
    $cat_dir = $_[0] if defined $_[0];
    return $cat_dir;
}
sub _creater {

    my($s) = path($cat_dir, "script")->children(qr/create\.pl/);
    l->debug("located creater script $s" );

    return $s;

} ## creater.t
sub _run_system {

    my @args = @_;
    my @args_to_show = @args;

    my ($o,$e,$r);

    ## hide db password:
    if (
        $args_to_show[0] =~ /_create\.pl$/ and
        $args_to_show[1] eq "model"
    ) {
        $args_to_show[8] = "<secret>" if
            defined $args_to_show[8] and
                $args_to_show[8] ne "";
    }

    if ( $ARGV{"--verbose"} ) {
        l->debug("system call [verbose]: @args_to_show");
        $r = system @args;
    }
    else {
        l->debug("system call: @args_to_show");
        ($o,$e,$r) = capture { system @args };
    }

    ## some known sdterr lines we do not show:
    if ($e) {
        my @e = split /\n/, $e;
        my @e2 = @e;
        @e2 = grep !/^Dumping manual schema for/, @e2;
        @e2 = grep !/^Schema dump completed\./, @e2;
        @e2 = grep !m{^Cannot determine perl version info from lib/.*\.pm}, @e2;

        ## hide all if we're testing non-verbosely
        @e2 = () if "@args" eq "make test" and not $ARGV{'--verbose'};

        print $_,"\n" for @e2;
    }

    if ( $r ) {
        l->fatal( "system call died. It definitely shouldn't have." );
        l->fatal( "command was: @args_to_show" );
    }

}
sub _finalize_argv {

    my $dsn_0 = $ARGV{'--dsn'};

    ## some booleans default on
    if ( not $ARGV{'--nodsnfix'} ) {
        $ARGV{'--dsnfix'} = $ARGV{'-dsnfix'} = 1
    }

    if ( not $ARGV{'--nopgpass'} ) {
        $ARGV{'--pgpass'} = $ARGV{'-pgpass'} = 1
    }
    ## defaults done

    ## html5 sets TT
    if ($ARGV{'--html5'}) {
        $ARGV{'-TT'} //= "HTML";
        $ARGV{'--TT'} //= "HTML";
    }

    ## views triggers json and tt
    if ( $ARGV{'--views'} ) {
        my %map;
        @map{qw/-TT --TT -JSON --JSON/} = qw/HTML HTML JSON JSON/;
        for (qw/-TT --TT -JSON --JSON/) {
            $ARGV{$_} ||= $map{$_};
        }
    }

    ## model can have the dsn
    if (defined $ARGV{'--model'} and $ARGV{'--model'} =~ /^dbi:/i ) {
        $ARGV{'--dsn'} = $ARGV{'--model'};
        $ARGV{'--model'} = 1;
    }

    ## dsn gets a brush up
    if ($ARGV{'--dsn'}) {

        if ( $ARGV{'--dsnfix'} ) {
            $ARGV{'--dsn'} = _prepare_dsn( $ARGV{'--dsn'} );
            $ARGV{'-dsn'} = $ARGV{'--dsn'};
        }

        if ( not defined $ARGV{'--model'} ) {
            $ARGV{'--model'} = 1;
        }

    }

    ## model might have defaults
    if ( $ARGV{'--model'} ) {

        if ( $ARGV{'--model'} eq '1' ) {
            $ARGV{'--model'} = $ARGV{'--name'} . 'DB';
        }

        $ARGV{'--model'} =~ s/^AppNameDB$/$ARGV{'--name'}DB/;
        $ARGV{'-model'} = $ARGV{'--model'};

        if ( not $ARGV{'--schema'} or $ARGV{'--schema'} eq "1" ) {
            $ARGV{'--schema'} = $ARGV{'--name'} . '::Schema';

            $ARGV{'-schema'} = $ARGV{'--schema'};

        }

    }
    else {
        delete $ARGV{'--schema'};
        delete $ARGV{'-schema'};
    }

    ## some defaults that will work for sqlite at least
    $ARGV{'--dbuser'} //= "";
    $ARGV{'--dbpass'} //= "";

    if ( defined $dsn_0 and $dsn_0 ne $ARGV{'--dsn'} ) {
        l->debug( "dsn changed to '$ARGV{'--dsn'}'" );
    }

} ## finalize_argv.t

## dsn related
sub _prepare_dsn {

    my $dsn = shift;

    return $dsn if $ARGV{'--nodsnfix'};

    ## unlikely but guess it could happen
    l->debug("Prepended litteral 'dbi' to dsn") if $dsn =~ s/^:/dbi:/;

    ## if it doesn't start with dbi: by now, we'll nicely provide that
    if ( lc substr( $dsn, 0, 4 ) ne "dbi:" ) {
        l->debug("Prepended 'dbi:' to dsn");
        $dsn = "dbi:" . $dsn;
    }

    ## taking care of case, should there be issues
    l->info("Setting dsn scheme to lowercase 'dbi:'" )
        if $dsn =~ /^.{0,2}[DBI]/;
    $dsn =~ s/^dbi:/dbi:/i;

    ## if it doesn't end with a ":" but has one alerady, we'll append
    ## one, should be enough to make it parseable by DBI, ie dbi:Pg
    ## will do
    if ( $dsn =~ y/:// == 1 and $dsn =~ /^dbi:/ and $dsn !~ /:$/ ) {
        l->info("Appending ':' to make dsn valid");
        $dsn .= ":";
    }

    ## offer to correct the driver
    my @parts = DBI->parse_dsn( $dsn );
    my $driver = _fix_dbi_driver_case( $parts[1] );

    my $case_fixed_dsn = sprintf(
        "%s:%s%s:%s",
        $parts[0],
        $driver, $parts[2]||"",
        $parts[4]
    );

    my $pgpass_fixed_dsn = _complete_dsn_from_pgpass($case_fixed_dsn);
    return $pgpass_fixed_dsn;

} ## dsn.t
sub _parse_dbi_dsn {

    my $dsn = shift;

    return unless defined $dsn;

    my @pairs = split /;/, $dsn;

    my %data;

    for (@pairs) {
        my ($k,$v) = split /=/, $_;
        $data{$k} = $v;
    }

    my $db = first {$_} delete @data{qw/db database dbname/};
    $data{database} = $db;

    my $host = first {$_} delete @data{qw/host hostname/};
    $data{host} = $host;

    $data{port} //= undef;

    return %data;

} ## dsn.t
sub _parse_dsn {

    my $dsn = shift ;

    my @parsed = DBI->parse_dsn($dsn);

    my $driver = _fix_dbi_driver_case($parsed[1]);

    my %hash = (driver => $driver, scheme => $parsed[0],
            attr_string => $parsed[2]);

    my %extra = _parse_dbi_dsn($parsed[4]);

    %hash = (%hash, %extra);

    return %hash;

} ## dsn.t
sub _known_drivers {
    return qw/ ADO CSV DB2 DBM Firebird MaxDB mSQL mysql mysqlPP ODBC
               Oracle Pg PgPP PO SQLite SQLite2 TSM XBase /;
}
sub _fix_dbi_driver_case {
    my @args = @_;
    my %hash;
    $hash{ lc $_ } = $_ for _known_drivers;
    ($_ = $hash{lc $_} || $_) for @args;

    if (not wantarray and @args == 1) {
        return $args[0];
    }
    return @args;
} ## fix_dbi_driver_case.t
sub _dsn_hash_to_dsn_string {
    my %dsn_hash = @_;

    my %dsn_last_part = %dsn_hash;
    my @first_parts = delete @dsn_last_part{qw/scheme driver attr_string/};
    $_ //= "" for @first_parts;

    my $last_part = "";
    while ( my($k,$v) = each %dsn_last_part ) {
        next if not defined $v or $v eq "";
        $last_part .= "$k=$v;";
    }
    $last_part =~ s/;$//;

    my $fixed_dsn = sprintf(
        "%s:%s%s:%s",
        @first_parts,
        $last_part
    );

    return $fixed_dsn;

}


## pgpass functions
sub _parse_pgpass {

    if (not -r path("~/.pgpass")) {
        l->debug( "~/.pgpass doesn't exist or can't be read" );
        return;
    }

    open my $fh, "<", path("~/.pgpass");

    my @entries;

    while ( <$fh> ) {
        chomp;
        my @values = split /:/, $_;

        my %row;
        @row{qw/host port database user pass/} = @values;

        ## not sure if this can ever happen
        $row{port} //= 5432;

        push @entries, \%row;

    }

    l->debug(sprintf "Parsed %d entries from ~/.pgpass",
        scalar @entries );

    return @entries;

} ## pgpass.t
sub _pgpass_entry_to_dsn {

    my $entry = shift;
    my $dsn = "dbi:Pg:";

    if ( my $d = $entry->{database} ) {
        $dsn .= "database=" . $d . ";";
    }
    if ( my $h = $entry->{host} ) {
        ## don't add if it's localhost
        $dsn .= "host=" . $h . ";" if $h !~ /^localhost(?:$|\.)/;
    }
    if ( my $p = $entry->{port} ) {
        ## don't add if its default 5432
        $dsn .= "port=" . $p . ";" if $p != 5432;
    }

    $dsn =~ s/;$//;

    return $dsn;

} ## pgpass.t
sub _complete_dsn_from_pgpass {

    my $dsn = shift;

    ## return unless there is a ~/.pgpass
    my @pgpass = _parse_pgpass or return $dsn;

    my %dsn = _parse_dsn( $dsn );

    ## only works with pg for obvious reasons
    if ( $dsn{driver} ne "Pg") {
        return $dsn;
    }

    ## if all is already set, no point to linger
    if ( all {$_} (@dsn{qw/database port host/},
                   @ARGV{qw/--dbuser --dbpass/})  ) {
        return $dsn;
    }

    my @candidate_pgpass =
        do {

            grep {

                my $entry = $_;

                all {

                    # my $test = (not defined $dsn{$_} or
                    #     ($dsn{$_}||"") eq ($entry->{$_}||""));

                    # print "# $_; test is ", $test, "\n";

                    ## This allows flexible matching, as long as there
                    ## is one single match, it could be on anything of
                    ## host, db or port
                    not defined $dsn{$_} or
                        ($dsn{$_}||"") eq ($entry->{$_}||"");

                } qw/host database port/;

            } @pgpass;

        };

    if ( not @candidate_pgpass) {
        l->info("Found no pgpass entries, not adding to dsn");
        return $dsn;
    }
    elsif ( @candidate_pgpass == 1 ) {
        l->info("Using one matching pgpass entry to add to dsn");

        _fill_dsn_parameters_from_pgpass_data
            ( \%dsn, $candidate_pgpass[0] );

        $ARGV{'--dbuser'} //= $candidate_pgpass[0]->{user};
        $ARGV{'--dbpass'} //= $candidate_pgpass[0]->{pass};
    }
    # elsif ( @candidate_pgpass < 6 and not $ARGV{'--noconnectiontest'} ) {

    #     ## in future we will grep for working connections
    #     my @passed_candidates = grep {

    #     }

    # }
    else {
       ## too many matches, don't bother
        l->info( sprintf "Too many (%d) matching ~/.pgpass entries found - using none",
             scalar @candidate_pgpass );
        return $dsn;
    }

    return _dsn_hash_to_dsn_string( %dsn );

}
sub _fill_dsn_parameters_from_pgpass_data {

    ## $data is a single entry as parsed from .pgpass
    my( $dsn_hash, $data ) = @_;

    $dsn_hash->{$_} //= $data->{$_} for qw/host database port/;

}

# create functions
sub _mk_app {

    _run_system( "catalyst.pl" => $ARGV{"--name"} );
    l->info( sprintf "Created catalyst app '%s'", $ARGV{"--name"} );

    _set_cat_dir( $ARGV{"--name"} );

} ## mk_app.t
sub _create_TT {

    return unless my $tt = $ARGV{"--TT"};

    _run_system( _creater() => "view", $tt, "TT" );

    my $tt_pm = _catalyst_path( "TT" );

    if ( not -f $tt_pm ) {
        l->error( "View module not found where it should be, exiting. " .
                      "You have to:\n 1: change ext to .tt2 and\n 2: set WRAPPER to wrapper.tt2." );
        return;
    }

    ## trust regex to modify the file
    my $pm = $tt_pm->slurp;

    if ( $pm =~ s/(TEMPLATE_EXTENSION\s*=>\s*'.tt)(',)/${1}2$2/ ) {
        l->debug("Changed template extension to .tt2");
    }
    else {
        l->warn("Failed changing template extension to .tt2");
    }

    if ( $pm =~ s/^(__PACKAGE__->config\()(\s+)/$1$2WRAPPER => 'wrapper.tt2',$2/ms ) {
        l->debug( "Added wrapper.tt2" );
    }
    else {
        l->warn( "Failed adding wrapper to view" );
    }

    $tt_pm->spew( $pm );

    ## alter config to set default view
    my $p = _catalyst_path( "lib", $ARGV{'--name'}.".pm" );
    my $config = $p->slurp;
    if ( $config =~ s/^(__PACKAGE__->config\()(\s+)/$1$2default_view => '$ARGV{"--TT"}',$2/ms ) {
        l->debug( "Configured default view: " . $ARGV{'--TT'} );
        $p->spew( $config );
    }
    else {
        l->warn( "Failed configuring default view" );
    }

    _catalyst_path( "root", "index.tt2" )->spew
        ( "Welcome to the brand new [% c.config.name %]!" );
    l->debug( "Wrote a basic index.tt2" );


    _catalyst_path( "root", "wrapper.tt2" )->spew
        ( "[% content %]\n" );
    l->debug( "Wrote an empty wrapper.tt2" );


    ## make index run template
    my $r = _catalyst_path( "C", "Root.pm" );

    my $substitute_this = q[$c->response->body( $c->welcome_message );];
    (my $root = $r->slurp) =~ s|\Q$substitute_this|# $&| and l->debug( "Commented response body message in sub index" );

    $r->spew( $root );

    l->info( sprintf "Created TT view as %s::View::%s",
             @ARGV{qw/--name --TT/}
         );

    _verify_TT_view();
    _verify_Root_index();

} ## create.tt
sub _create_JSON {

    return unless my $json = $ARGV{"--JSON"};

    _run_system( _creater() => "view", $json, "JSON" );

    my $p = _catalyst_path( "JSON" );
    my $json_code = $p->slurp;

    my $extra = <<'JSON';

__PACKAGE__->config(
    # expose only the json key in stash
    expose_stash => [ qw(json) ],
);
JSON

    if ( not $json_code =~ s/use base 'Catalyst::View::JSON';/$&\n$extra/ ) {
        # l->error("failed configuring expose_stash in json");
    }

    $p->spew( $json_code );

    l->info( sprintf "Created JSON view as %s::View::%s",
             @ARGV{qw/--name --JSON/}
     );

    _verify_JSON_view();

} ## create_json.tt
sub _mk_views {

    if ( $ARGV{'--TT'} ) {
        _create_TT;
    }

    if ( $ARGV{'--JSON'} ) {
        _create_JSON;
    }

}
sub _mk_model {

    return unless my $model_name = $ARGV{'--model'};

    _run_system( _creater() => "model", $model_name,
                 "DBIC::Schema", $ARGV{'--schema'},
                 "create=static",
                 @ARGV{qw/--dsn --dbuser --dbpass/},
             );

    l->info(sprintf "Created model: dsn=%s, model=%s and schema=%s",
            @ARGV{qw/--dsn --model --schema/}
        );

}
sub _mk_html5 {

    if ( not $ARGV{'--html5'} ) {
        return
    }

    App::CatalystStarter::Bloated::Initializr::deploy( _catalyst_path("root") );

    _catalyst_path( "root", "index.tt2" )->spew(<<'EOS');
<div class="row">

<div class="col-lg-4">
<h2>Hi there</h2>
<p>Welcome to the brand new [% c.config.name %]!</p>
</div>

<div class="col-lg-4">
<h2>Nav bar on top</h2>
<p>Nav bar setup is easily parameterized or edited in source.</p>
</div>

<div class="col-lg-4">
<h2>Jumbotron</h2>
<p>The Jumbotron goes away is c->stash->{jumbotron} is not set. The
template comes from initializr.com. More templates will come in future
updates.</p>
<p><a class="btn btn-default" href="http://www.initializr.com">View details &raquo;</a></p>
</div>

</div>
EOS

    my $p = _catalyst_path( "C", "Root.pm" );

    my $substitute_this = q[$c->response->body( $c->welcome_message );];
    my $with_this = q[$c->stash->{jumbotron} = { header => "Splashy message", body => "This is a 'jumbotron' header, view source and check Root controller for details" };] . "\n";
    (my $root = $p->slurp) =~ s|(?:# )?\Q$substitute_this|$&\n    $with_this|
        or l->error("Failed inserting jumbotron");

    $p->spew( $root );

    _verify_Root_jumbatron();

}


## test related
sub _test_new_cat {

    return if $ARGV{'--notest'};

    chdir $cat_dir;

    ## Assumes cwd is at cat_dir
    if ( _run_system "perl" => "Makefile.PL" ) {
        l->error( "Makefile.PL failed" );
        return;
    }
    elsif ( _run_system "make" ) {
        l->error( "make failed" );
        return;
    }
    elsif ( _run_system "make" => "test" ) {
        l->error( "make test failed" );
        return;
    }

    l->info( "Catalyst tests ok" );

    chdir "..";

}
sub _verify_TT_view {

    my $view_file = $_[0] || _catalyst_path( "TT" );

    return if not defined $view_file;

    eval { require $view_file };

    if ( $@ ) {
        l->error( "$view_file contains errors and must be edited by hand." );
        l->error( "$@" );
        return;
    }

    my $view_class = $ARGV{'--name'} . "::View::" . $ARGV{'--TT'};

    my $cnf = $view_class->config;
    if ( not defined $cnf->{WRAPPER} or $cnf->{WRAPPER} ne "wrapper.tt2" ) {
        l->error( "$view_class didn't get WRAPPER properly configured, must be fixed manually." );
    }
    if ( not defined $cnf->{TEMPLATE_EXTENSION} or $cnf->{TEMPLATE_EXTENSION} ne ".tt2" ) {
        l->error( "$view_class didn't get TEMPLATE_EXTENSION properly configured, must be fixed manually." );
    }

    l->debug( "Modifications to TT view ok" );

} ## verify_tt.t
sub _verify_Root_index {

    my $root_controller_file = $_[0] || _catalyst_path( "C", "Root.pm" );

    if ( not ref $root_controller_file ) {
        $root_controller_file = path( $root_controller_file );
    }

    my $root_controller = $root_controller_file->slurp;

    if ( $root_controller =~ /^\s+\$c->response->body.*welcome_message/m ) {
       l->error( "Failed fixing Root controller. Comment out the response body line." );
       l->error( "Root contents:" );
       l->error( $root_controller );
    }

    l->debug( "Root controller set to run index.tt2" );

}
sub _verify_Root_jumbatron {

    my $root_controller_file = $_[0] || _catalyst_path( "C", "Root.pm" );

    if ( not ref $root_controller_file ) {
        $root_controller_file = path( $root_controller_file );
    }

    my $root_controller = $root_controller_file->slurp;

    if ( $root_controller !~ /stash.*jumbotron.*header.*body/ ) {
       l->error( "Failed adding jumbotron example to Root controller" );
    }

    l->debug( "Sample jumbotron data added to Root controller" );

}
sub _verify_JSON_view {

    my $view_file = $_[0] || _catalyst_path( "JSON" );

    return if not defined $view_file;

    eval { require $view_file };

    if ( $@ ) {
        l->error( "$view_file contains errors and must be edited by hand." );
        l->error( "$@" );
        return;
    }

    my $view_class = $ARGV{'--name'} . "::View::" . $ARGV{'--JSON'};

    my $cnf = $view_class->config;
    if ( not defined $cnf->{expose_stash} or
             ref $cnf->{expose_stash} ne "ARRAY" or
                 $cnf->{expose_stash}[0] ne "json"
         ) {
        l->error( "$view_class didn't get expose_stash properly configured, ".
                      "must be fixed manually, expected to be ['json']." );
    }

    l->debug( "Modifications to JSON view ok" );

} ## verify_json.t

## This does it all
sub run {

    ## complete with logic not covered in G::E
    _finalize_argv;

    ## 1: Create a catalyst
    _mk_app;

    ## 2: Create views
    _mk_views;

    ## 3: Make model
    _mk_model;

    ## 4: setup html template
    _mk_html5;

    ## 5: test new catalyst
    _test_new_cat;

    l->info( "Catalyst setup done" );

}

1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

App::CatalystStarter::Bloated - Creates a catalyst app, a TT view, a model and a HTML5 wrapper template from initalizr.com.

=head1 VERSION

This document describes App::CatalystStarter::Bloated version 0.9.3

=head1 SYNOPSIS

    # dont use this module, use the installed script
    # catalyst-fatstart.pl instead

=head1 DESCRIPTION

This distribution provides an alternative script to start catalyst
projects: catalyst-fatstart.pl

This script takes a number of options, see catalyst-fatstart.pl
--usage , --man and --help

In short it does the following:

=over

=item *

Calls catalyst.pl to create the catalyst project

=item *

Sets up a TT view as ::HTML and a JSON view as ::JSON

=item *

If given a --dsn, runs create model and provides default names
for schema and model classes.

=item *

If using a dbi:Pg dsn, looks in your ~/.pgpass to find usernames
and passwords and even intelligently completes your dsn if you are
missing hostname and or port.

=item *

Sets up a TT wrapper based on a HTML5 template intializr.com and
points its css, js images and fonts to /static

=back

=head1 INTERFACE

=head2 run

The function that does it all.

=head1 DIAGNOSTICS

Will come in next version

=head1 CONFIGURATION AND ENVIRONMENT

App::CatalystStarter::Bloated requires no configuration files or environment variables.

=head1 DEPENDENCIES

Several. Makefile/Build should take care of them.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-catalyststarter-bloated@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 SEE ALSO

L<Catalyst::Runtime>

=head1 AUTHOR

Torbjørn Lindahl  C<< <torbjorn.lindahl@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, Torbjørn Lindahl C<< <torbjorn.lindahl@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
