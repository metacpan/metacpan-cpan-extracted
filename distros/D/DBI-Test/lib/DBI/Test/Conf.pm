package DBI::Test::Conf;

use strict;
use warnings;

use Carp qw(carp croak);
use Config;

use Cwd            ();
use Data::Dumper   ();
use File::Basename ();
use File::Path     ();
use File::Spec     ();

use DBI::Mock                ();
use DBI::Test::DSN::Provider ();

use Module::Pluggable::Object ();

my $cfg_plugins;

sub cfg_plugins
{
    defined $cfg_plugins and return @{$cfg_plugins};

    my $finder = Module::Pluggable::Object->new(
                                                 search_path => ["DBI::Test"],
                                                 require     => 1,
                                                 only        => qr/::Conf$/,
                                                 inner       => 0
                                               );
    my @plugs = grep { $_->isa("DBI::Test::Conf") } $finder->plugins();
    $cfg_plugins = \@plugs;

    return @{$cfg_plugins};
}

my %conf = (
             (
               -f $INC{'DBI.pm'}
               ? (
                   default => {
                                category   => "mock",
                                cat_abbrev => "m",
                                abbrev     => "b",
                                init_stub  => qq(\$ENV{DBI_MOCK} = 1;),
                                match      => {
                                           general   => qq(require DBI;),
                                           namespace => [""],
                                         },
                                name => "Unmodified Test",
                              }
                 )
               : ()
             )
           );

sub conf { %conf; }

sub allconf
{
    my ($self)  = @_;
    my %allconf = $self->conf();
    my @plugins = $self->cfg_plugins();
    foreach my $plugin (@plugins)
    {
        # Hash::Merge->merge( ... )
        %allconf = ( %allconf, $plugin->conf() );
    }
    return %allconf;
}

my $tc_plugins;

sub tc_plugins
{
    defined $tc_plugins and return @{$tc_plugins};

    my $finder = Module::Pluggable::Object->new(
                                                 search_path => ["DBI::Test"],
                                                 require     => 1,
                                                 only        => qr/::List$/,
                                                 inner       => 0
                                               );
    my @plugs = grep { $_->isa("DBI::Test::List") } $finder->plugins();
    $tc_plugins = \@plugs;

    return @{$tc_plugins};
}

sub alltests
{
    my ($self) = @_;
    my @alltests;
    my @plugins = $self->tc_plugins();
    foreach my $plugin (@plugins)
    {
        # Hash::Merge->merge( ... )
        @alltests = ( @alltests, $plugin->test_cases() );
    }
    return @alltests;
}

sub alldrivers
{
    # XXX restrict by config file !
    my @drivers = grep { $_ !~ m/^Gofer|Multi|Multiplex|Proxy|Sponge$/ } DBI->available_drivers();
    # hack around silly DBI behaviour which removes NullP from avail drivers
    -f $INC{'DBI.pm'} and push( @drivers, "NullP" );
    @drivers;
}

sub default_dsn_conf
{
    my ( $self, $driver ) = @_;

    $driver => {
                 category   => "driver",
                 cat_abbrev => "d",
                 abbrev     => lc( substr( $driver, 0, 1 ) ),
                 driver     => "dbi:$driver:",
                 name       => "DSN for $driver",
               };
}

sub dsn_conf
{
    my ( $self, $driver, $test_case_ns ) = @_;
    my @dsn_providers =
      grep { $_ =~ m/\b$driver$/ && $_->can("dsn_conf") } DBI::Test::DSN::Provider->dsn_plugins();
    @dsn_providers or return $self->default_dsn_conf($driver);
    return $dsn_providers[0]->dsn_conf($test_case_ns);
}

sub combine_nk
{
    my ( $n, $k ) = @_;
    my @indx;
    my @result;

    @indx = map { $_ } ( 0 .. $k - 1 );

  LOOP:
    while (1)
    {
        my @line = map { $indx[$_] } ( 0 .. $k - 1 );
        push( @result, \@line ) if @line;
        for ( my $iwk = $k - 1; $iwk >= 0; --$iwk )
        {
            if ( $indx[$iwk] <= ( $n - 1 ) - ( $k - $iwk ) )
            {
                ++$indx[$iwk];
                for my $swk ( $iwk + 1 .. $k - 1 )
                {
                    $indx[$swk] = $indx[ $swk - 1 ] + 1;
                }
                next LOOP;
            }
        }
        last;
    }

    return @result;
}

# simplified copy from Math::Cartesian::Product
# Copyright (c) 2009 Philip R Brenan.
# This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.

sub cartesian
{
    my @C = @_;    # Lists to be multiplied
    my @c = ();    # Current element of cartesian product
    my @P = ();    # Cartesian product
    my $n = 0;     # Number of elements in product

    @C or return;  # Empty product

    # Generate each cartesian product when there are no prior cartesian products.

    my $p;
    $p = sub {
        if ( @c < @C )
        {
            for ( @{ $C[@c] } )
            {
                push @c, $_;
                &$p();
                pop @c;
            }
        }
        else
        {
            my $p = [@c];
            push @P, $p;
        }
    };

    &$p();

    @P;
}

sub create_test
{
    my ( $self, $test_case, $cfg_pfx, $test_confs, $dsn_pfx, $dsn_cred, $options ) = @_;

    # simply don't deploy them when you don't want be bothered about them ...
    my $test_base =
      ( defined( $options->{AUTHOR_TESTS} ) and $options->{AUTHOR_TESTS} ) ? "xt" : "t";
    ( my $test_file = $test_case ) =~ s,::,/,g;
    $test_file = File::Spec->catfile( $test_base, $test_file . ".t" );
    my $test_dir = File::Basename::dirname($test_file);

    $test_file = File::Basename::basename($test_file);
    my @tf_name_parts;
    $cfg_pfx and push( @tf_name_parts, $cfg_pfx );
    $dsn_pfx and push( @tf_name_parts, $dsn_pfx );
    push( @tf_name_parts, $test_file );
    $test_file = File::Spec->catfile( $test_dir, join( "_", @tf_name_parts ) );

    -d $test_dir or File::Path::make_path($test_dir);
    open( my $tfh, ">", $test_file ) or croak("Cannot open \"$test_file\": $!");
    my $init_stub = join(
        ";\n",
        map {
            "ARRAY" eq ref( $_->{init_stub} )
              ? join( ";\n", @{ $_->{init_stub} } )
              : $_->{init_stub}
          } grep { $_->{init_stub} } @$test_confs
    );
    $init_stub and $init_stub = sprintf( <<EOS, $init_stub );
BEGIN {
%s
}
EOS
    my $cleanup_stub = join(
        ";\n",
        map {
            "ARRAY" eq ref( $_->{cleanup_stub} )
              ? join( ";\n", @{ $_->{cleanup_stub} } )
              : $_->{cleanup_stub}
          } grep { $_->{cleanup_stub} } @$test_confs
    );
    $cleanup_stub and $cleanup_stub = sprintf( <<EOC, $cleanup_stub );
END {
%s
}
EOC

    my $dsn =
      Data::Dumper->new( [$dsn_cred] )->Indent(0)->Sortkeys(1)->Quotekeys(0)->Terse(1)->Dump();
    # XXX how to deal with namespaces here and how do they affect generated test names?
    my $test_case_ns = "DBI::Test::Case::$test_case";
    my $test_case_code = sprintf( <<EOC, $init_stub, $cleanup_stub, $dsn );
#!$^X\n
%s
%s
use DBI::Mock;
use DBI::Test::DSN::Provider;

use ${test_case_ns};

my \$test_case_conf = DBI::Test::DSN::Provider->get_dsn_creds("${test_case_ns}", %s);
${test_case_ns}->run_test(\$test_case_conf);
EOC

    print $tfh "$test_case_code\n";
    close($tfh);

    return $test_dir;
}

sub create_conf_prefixes
{
    my ( $self, $allconf ) = @_;
    my %pfx_hlp;
    my %pfx_lst;

    foreach my $cfg ( values %$allconf )
    {
        push( @{ $pfx_hlp{ $cfg->{cat_abbrev} } }, $cfg );
    }

    foreach my $cfg_id ( keys %pfx_hlp )
    {
        my $n = scalar( @{ $pfx_hlp{$cfg_id} } );
        my @combs = map { combine_nk( $n, $_ ); } ( 1 .. $n );
        scalar @combs or next;
        $pfx_lst{$cfg_id} = {
            map {
                my @cfgs = map { $pfx_hlp{$cfg_id}->[$_] } @{$_};
                my $pfx = "${cfg_id}v" . join( "", map { $_->{abbrev} } @cfgs );
                $pfx => \@cfgs
              } @combs
        };
    }

    my %pfx_direct = map { %{$_} } values %pfx_lst;
    %pfx_hlp = %pfx_lst;
    %pfx_lst = ( "" => [] );
    do
    {
        my @pfx   = keys %pfx_hlp;
        my $n     = scalar(@pfx);
        my @combs = map { combine_nk( $n, $_ ); } ( 1 .. $n );
        foreach my $comb (@combs)
        {
            my @cfgs = cartesian( map { [ keys %{ $pfx_hlp{ $pfx[$_] } } ] } @$comb );
            foreach my $cfg (@cfgs)
            {
                my $_pfx = join( "_", @$cfg );
                $pfx_lst{$_pfx} = [ map { @{ $pfx_direct{$_} } } @$cfg ];
            }
        }
    } while (0);

    return %pfx_lst;
}

my %dsn_cfg = (
                dbm => {
                         category   => "driver",
                         cat_abbrev => "d",
                         abbrev     => "d",
                         driver     => "dbi:DBM:",
                         variants   => {
                                       mldbm => {
                                                  f => { dbm_mldbm => 'FreezeThaw' },
                                                  d => { dbm_mldbm => 'Data::Dumper' },
                                                  s => { dbm_mldbm => 'Storable' },
                                                },
                                       type => {
                                                 s => { dbm_type => 'SDBM_File' },
                                                 g => { dbm_type => 'GDBM_File' },
                                                 d => { dbm_type => 'DB_File' },
                                                 b => {
                                                        dbm_type           => 'BerkeleyDB',
                                                        dbm_berkeley_flags => '...'
                                                      }
                                               },
                                     },
                         name => "DSN for DBM",
                       },
                csv => {
                         category   => "driver",
                         cat_abbrev => "d",
                         abbrev     => "c",
                         driver     => "dbi:CSV:",
                         variants   => {
                                       type => {
                                                 p => { csv_class => 'Text::CSV' },
                                                 x => { csv_class => 'Text::CSV_XS' },
                                               },
                                     },
                         name => "DSN for CSV",
                       },
              );

sub create_driver_prefixes
{
    my ( $self, $dsnconf ) = @_;
    # $dsnconf or $dsnconf = \%dsn_cfg;
    my %pfx_lst;

    foreach my $dsncfg ( values %$dsnconf )
    {
        my @creds = @$dsncfg{qw(driver user passwd attrs)};
        my $pfx   = $dsncfg->{cat_abbrev} . "v" . $dsncfg->{abbrev};
        "HASH" eq ref $creds[3] or $creds[3] = {};
        $pfx_lst{$pfx} = [@creds];

        if ( $dsncfg->{variants} )
        {
            my @varvals = values %{ $dsncfg->{variants} };
            my @variants = cartesian( map { [ keys %{$_} ] } @varvals );
            foreach my $variant (@variants)
            {
                my $attrs = {
                              %{ $creds[3] },
                              map { %{ $varvals[$_]->{ $variant->[$_] } } } ( 0 .. $#varvals )
                            };
                $pfx_lst{ $pfx . join( "", @$variant ) } = [ @creds[ 0 .. 2 ], $attrs ];
            }
        }
    }

    # avoid prefix pollution
    if ( 1 == scalar( keys(%pfx_lst) ) )
    {
        %pfx_lst = ( '' => ( values %pfx_lst )[0] );
    }

    return %pfx_lst;
}

sub populate_tests
{
    my ( $self, $alltests, $allconf, $alldrivers, $options ) = @_;
    my %test_dirs;

    my %pfx_cfgs = $self->create_conf_prefixes($allconf);
    foreach my $test_case (@$alltests)
    {
        # XXX how to deal with namespaces here and how do they affect generated test names?
        my $test_case_ns = "DBI::Test::Case::$test_case";
        eval "require $test_case_ns;";
        $@ and carp $@ and next;    # don't create tests for broken test cases
        my @test_drivers = @$alldrivers;
        $test_case_ns->can("filter_drivers")
          and @test_drivers = $test_case_ns->filter_drivers( $options, @test_drivers );
        @test_drivers or next;

        $test_case_ns->can("supported_variant")
          or eval qq/
	      package #
	        $test_case_ns;
	    sub supported_variant { 1 };
	    1;
	  /;

        my %dsn_conf;
        foreach my $test_drv (@test_drivers)
        {
            %dsn_conf = ( %dsn_conf, $self->dsn_conf( $test_drv, $test_case_ns ) );
        }
        my %pfx_dsns = $self->create_driver_prefixes( \%dsn_conf );

        foreach my $pfx_dsn ( keys %pfx_dsns )
        {
            foreach my $pfx_cfg ( keys %pfx_cfgs )
            {
                $test_case_ns->supported_variant(
                                                  $test_case,          $pfx_cfg,
                                                  $pfx_cfgs{$pfx_cfg}, $pfx_dsn,
                                                  $pfx_dsns{$pfx_dsn}, $options
                                                )
                  or next;
                my $test_dir = $self->create_test(
                                               $test_case, $pfx_cfg,            $pfx_cfgs{$pfx_cfg},
                                               $pfx_dsn,   $pfx_dsns{$pfx_dsn}, $options );
                $test_dirs{$test_dir} = 1;
            }
        }
    }

    return keys %test_dirs;
}

sub setup
{
    my ( $self, %options ) = @_;

    my %allconf = $self->allconf();
    # from DBI::Test::{NameSpace}::List->test_cases()
    my @alltests   = $self->alltests();
    my @alldrivers = $self->alldrivers();

    my @gen_test_dirs = $self->populate_tests( \@alltests, \%allconf, \@alldrivers, \%options );

    if ( $options{SKIP_FILE} )
    {
        open( my $fh, ">", $options{SKIP_FILE} )
          or croak("Can't open $options{SKIP_FILE} for writing: $!");
        print $fh map { $_ . "/.*\\.t\n"; } @gen_test_dirs;
        close($fh);
    }

    return map { File::Spec->catfile( $_, "*.t" ) } @gen_test_dirs;
}

=head1 NAME

DBI::Test::Conf - provides variants configuration for DBI::Test

=head1 DESCRIPTION

This module provides the configuration of variants for tests
generated from DBI::Test::Case list.

=head1 AUTHOR

This module is a team-effort. The current team members are

  H.Merijn Brand   (Tux)
  Jens Rehsack     (Sno)
  Peter Rabbitson  (ribasushi)
  Joakim TE<0x00f8>rmoen   (trmjoa)

=head1 COPYRIGHT AND LICENSE

Copyright (C)2013 - The DBI development team

You may distribute this module under the terms of either the GNU
General Public License or the Artistic License, as specified in
the Perl README file.

=cut

1;
