package BugCli::Config;

push @BugCli::ISA, __PACKAGE__
  unless grep { $_ eq __PACKAGE__ } @BugCli::ISA;

use Config::Tiny;
use Text::Table;
use Term::ANSIColor qw(:constants);
use strict;

our (@keys) =
  qw|users commands product_product_id product_component_id server query product|;

BEGIN {
    $Term::ANSIColor::AUTORESET = 1;

}

sub config_show_users {
    print "Section: User list\n";
    my $tb = Text::Table->new(qw|Id Login|);
    $tb->add( $_, $BugCli::uid_to_login{$_} )
      foreach ( keys %BugCli::uid_to_login );
    print $tb;
}

sub config_show_commands {
}

sub config_show_product {
    my ($self) = @_;
    print "Section: Product\n";
    print "Current Product Id: $BugCli::config->{'product'}->{'product_id'}\n";
    print
      "Current Component Id: $BugCli::config->{'product'}->{'component_id'}\n";
    print "Other variants: \n";
    $self->config_show_product_product_id(1);
    $self->config_show_product_component_id(1);
}

sub config_show_product_product_id {

    my ( $self, $dont ) = @_;
    print "Section: Products List\n";
    my ($t)        = Text::Table->new(qw|Id Name Description|);
    my ($products) = $BugCli::dbh->fetch_select(
        "columns" => [qw|id name description|],
        "table"   => "products"
    );
    foreach my $p ( @{$products} ) {
        $t->add( $$p{id}, $$p{name}, $$p{description} );
    }

    print $t;
}

sub config_show_product_component_id {
    my ( $self, $dont ) = @_;
    print "Config Section: Component list (for selected product)\n";
    my ($t)     = Text::Table->new(qw|Id Name Description|);
    my ($comps) = $BugCli::dbh->fetch_select(
        "columns"  => [qw|id name description|],
        "table"    => "components",
        "criteria" =>
          { "product_id" => $BugCli::config->{'product'}->{'product_id'} }
    );

    foreach my $c ( @{$comps} ) {
        $t->add( $$c{id}, $$c{name}, $$c{description} );
    }

    print $t;

}

sub config_show_server {
    my ($self) = @_;
    print GREEN
      . "Section:"
      . WHITE
      . " Bugzilla Server Options"
      . RESET . "\n";
    my ($tb) = Text::Table->new(qw|Option Value Description|);
    $tb->add(
        'server.host',
        $BugCli::config->{server}->{host},
        "MySQL server address"
    );
    $tb->add(
        'server.username',
        $BugCli::config->{server}->{username},
        "MySQL Username for accessing the database"
    );
    $tb->add(
        'server.password',
        $BugCli::config->{server}->{password},
        "MySQL access password"
    );
    $tb->add(
        'server.table',
        $BugCli::config->{server}->{table},
        "Name of the MySQL table that holds the BugZilla"
    );
    $tb->add(
        'server.login',
        $BugCli::config->{server}->{login},
        "Bugzilla login, usually email"
    );
    $tb->rule( '-', '+', "|" );
    print $tb;

}

sub config_show_query {
    my ( $self, $dont ) = @_;
    my ( $i, $qname ) = ( 'Description/Code', 'Option' );
    open Z2, ">-";

    format Z2 =
@<<<<<<<<<<...    ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$qname ,    $i
            ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
            $i
.
    print GREEN . "\nSection: " . WHITE . "Available queries" . RESET . "\n"
      unless defined $dont;
    write Z2;

    foreach $qname ( keys %{ $BugCli::config->{query} } ) {
        if ( exists $BugCli::config->{"query.descr"}->{$qname} ) {
            $i = $BugCli::config->{"query.descr"}->{$qname};
        }
        else {
            $i = $BugCli::config->{query}->{$qname};
        }
        $qname = "query.$qname" unless defined $dont;
        write Z2;
    }
    close Z2;

}

# read_config (return true only if mandatory config options are set) {{{
sub read_config {
   $BugCli::config             = Config::Tiny->read($ENV{HOME} . '/bugcli.cfg');
   return         
         exists $BugCli::config->{server} 
      && exists $BugCli::config->{server}->{host}
      && exists $BugCli::config->{product} 
      && exists $BugCli::config->{server}->{username}
      && exists $BugCli::config->{server}->{table}
      && exists $BugCli::config->{product}->{product_id}
      && exists $BugCli::config->{product}->{component_id}
      && exists $BugCli::config->{server}->{login};
}

# }}}

# write_config (little wrap-up for writing config values) {{{
sub write_config {
    my ( $self, $ahost, $auser, $apass, $atbl, $alogin ) = @_;
    $BugCli::config = Config::Tiny->new() if(not defined $BugCli::config or !scalar(keys %{$BugCli::config}));
    $BugCli::config->{server}->{host}     = $ahost  if defined $ahost;
    $BugCli::config->{server}->{username} = $auser  if defined $auser;
    $BugCli::config->{server}->{password} = $apass  if defined $apass;
    $BugCli::config->{server}->{table}    = $atbl   if defined $atbl;
    $BugCli::config->{server}->{login}    = $alogin if defined $alogin;
    $BugCli::config->write($ENV{HOME} . '/bugcli.cfg');

}

# }}}

sub print_config {
    my ( $self, $cmd, $cat, $val ) = @_;
    no strict 'refs';
    my ( @v, $f );
    if ( defined $cat ) {
        if ( $cat =~ /^(.*?)\.(.*?)$/ and not exists $BugCli::config->{$cat} ) {
            $cat = $1;
            $val = $2;
        }
        $f = "BugCli::Config::config_show_$cat";
        $f .= "_$val" if defined $val;
        if ( defined &$f ) {
            push @v, $f;
        }
        else {
            if ( defined $val ) {
	 	if( exists $BugCli::config->{$cat}->{$val} ) {
                    print "Section: $cat Option: $val\n";
                    print "Value: $BugCli::config->{$cat}->{$val}\n";
		}else {
		    print "Sorry, such sub-option '$val' doesn't exist! \n";
		}
		
            }
            else {
                print "Section: $cat \n";
                print "Option: $_ Value: $BugCli::config->{$cat}->{$_}\n"
                  foreach ( keys %{ $BugCli::config->{$cat} } );
            }
        }
    }
    else {
        @v = map { "BugCli::Config::config_show_$_" } @keys if not defined $cat;
    }
    foreach my $k (@v) {
        if ( defined &$k ) { &$k($self); }
    }

}

# run_config (asks for config settings for whole groups, or partial values) {{{
sub run_config {
    my ( $self, $param ) = @_;
    print_config(@_), return if defined $param and $param eq 'show';
    my ( $ahost, $auser, $apass, $atbl, $alogin ) = (
        $BugCli::config->{server}->{host}     || '',
        $BugCli::config->{server}->{username} || '',
        $BugCli::config->{server}->{password} || '',
        $BugCli::config->{server}->{table}    || '',
        $BugCli::config->{server}->{login}    || ''
    );
    if ( $param && defined $BugCli::config ) {    #ok. something specific...
        if ( $param =~ /^(.*?)\.(.*)$/ ) {
            print "Current value of $param is $BugCli::config->{$1}->{$2}.\n"
              if exists $BugCli::config->{$1}->{$2};
            $BugCli::config->{$1}->{$2} =
              $self->prompt( "Please enter new value for $param:",
                $BugCli::config->{$1}->{$2} );
        }
        else { print "No such config group found, sorry...\n"; }
        return;
    }
    print "Sorry, no config found. Starting configuration. \n"
      if not read_config();

    $ahost  = $self->prompt( "MySQL Bugzilla Host: ($ahost)",      $ahost );
    $auser  = $self->prompt( "MySQL Username: ($auser)",           $auser );
    $apass  = $self->prompt( "MySQL Password: ($apass)",           $apass );
    $atbl   = $self->prompt( "MySQL Bugzilla Table Name: ($atbl)", $atbl );
    $alogin = $self->prompt( "User login (email): ($alogin)",      $alogin );
    $self->write_config( $ahost, $auser, $apass, $atbl, $alogin );
    print "Trying to init your configuration...\n";
    $self->init_mysql();

    my ($products) = $BugCli::dbh->fetch_select(
        "columns" => [qw|id name description|],
        "table"   => "products"
    );
    print "Please select a product you're gonna work with: \n\n";
    my ($t) = Text::Table->new(qw|Id Name Description|);
    foreach my $p ( @{$products} ) {
        $t->add( $$p{id}, $$p{name}, $$p{description} );
    }
    print $t;
    my ($pid)   = $self->prompt("Please select a product's id: ");
    my ($comps) = $BugCli::dbh->fetch_select(
        "columns"  => [qw|id name description|],
        "table"    => "components",
        "criteria" => { "product_id" => $pid }
    );
    $t->clear();

    print "\nPlease select a component to work on: ";
    foreach my $c ( @{$comps} ) {
        $t->add( $$c{id}, $$c{name}, $$c{description} );
    }

    print $t;
    my ($cid) = $self->prompt("Please select a component's id: ");
    $BugCli::config->{product}->{product_id}   = $pid;
    $BugCli::config->{product}->{component_id} = $cid;
    $BugCli::config->write($ENV{HOME} . '/bugcli.cfg');
    BugCli::init_mysql();

}

# }}}

# unload_defaults (extracts default config options) {{{
sub unload_defaults {
    $BugCli::config->{"bind"}->{"c1"}      = "bugs my";
    $BugCli::config->{"command"}->{"c1"}   = '\cQ';
    $BugCli::config->{"query"}->{"all"}    = "SELECT * FROM bugs";
    $BugCli::config->{"query"}->{"allnew"} =
      "SELECT * FROM bugs where resolution != 'FIXED'";
    $BugCli::config->{"query"}->{'my'} =
"SELECT * FROM bugs where assigned_to=\%uid and (bug_status='NEW' or bug_status='ASSIGNED' or bug_status='REOPENED')";
    $BugCli::config->{"query"}->{"myall"} =
      "SELECT * FROM bugs where assigned_to=\%uid";
    $BugCli::config->{"query"}->{"regexp"} =
      "SELECT * FROM bugs where short_desc REGEXP '\%regexp'";
    $BugCli::config->{"query.descr"}->{"my"} =
      "All un-resolved bugs, owned by me (default key Ctrl-Q)";
}

# }}}

1;

