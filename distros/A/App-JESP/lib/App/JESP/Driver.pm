package App::JESP::Driver;
$App::JESP::Driver::VERSION = '0.013';
use Moose;

=head1 NAME

App::JESP::Driver - DB Specific stuff superclass.

=cut

use Log::Any qw/$log/;
use DBI;
use IPC::Run;

has 'jesp' => ( is => 'ro' , isa => 'App::JESP', required => 1, weak_ref => 1);

=head2 apply_patch

Applies the given L<App::JESP::Patch> to the database. Dies in case of error.

You do NOT need to implement that in subclasses.

Usage:

  $this->apply_patch( $patch );

=cut

sub apply_patch{
    my ($self, $patch) = @_;
    $log->info("Applying patch ".$patch->id());
    if( my $sql = $patch->sql() ){
        $log->trace("Patch is SQL='$sql'");
        return $self->apply_sql( $sql );
    }
    if( my $script_file = $patch->script_file() ){
        $log->trace("Patch is SCRIPT='".$script_file."'");
        return $self->apply_script( $script_file );
    }
}

=head2 apply_script

Runs the given 'script' file, with the given environment:

  JESP_DSN : The full Perl DSN string
  JESP_USER: DB User
  JESP_PASSWORD: DB Password
  JESP_SCHEME: 'dbi'
  JESP_DRIVER: The name of the DBI driver in use
  JESP_DRIVER_DSN: the part of the DSN after the driver

Then the JESP_DRIVER_DSN is parsed and split into its components to generate environment variables.
The most common is:

  JESP_DATABASE: Name of the database to connect to
  JESP_PORT: The port to connect to.
  ...

=cut

sub apply_script{
    my ($self, $script) = @_;

    my @cmd = ( $script );

    my $input = '';

    my $on_stdout = sub{
        $log->info( @_ );
    };
    my @stderr;
    my $on_stderr = sub{
        $log->warn( @_ );
        push @stderr , @_;
    };

    my $properties = {};
    my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn( $self->jesp()->dsn() );
    ref($self)->_OdbcParse( $driver_dsn , $properties , [] );
    $properties->{user} ||= $self->jesp()->username();
    $properties->{password} ||= $self->jesp()->password();
    $properties = {
        %$properties,
        %{ defined( $attr_hash ) ? $attr_hash : {} },
        dsn => $self->jesp()->dsn(),
        scheme => $scheme,
        driver => $driver,
        driver_dsn => $driver_dsn,
        attr_string => $attr_string,
    };
    my %EXTRA_ENV = ();
    # Outside testing, be verbose.
    $EXTRA_ENV{IPCRUNDEBUG} = 'basic' unless( $ENV{AUTOMATED_TESTING} || $ENV{HARNESS_ACTIVE} );
    # Transfer all the DB properties
    foreach my $key ( keys %{$properties} ){
        if( $properties->{$key} ){
            $EXTRA_ENV{'JESP_'.uc($key)} = $properties->{$key};
        }
    }

    local %ENV = ( %ENV , %EXTRA_ENV );
    IPC::Run::run( \@cmd , \$input , $on_stdout , $on_stderr ) or die join(' ', @cmd).": $? : ".join("\n", @stderr )."\n";
}


=head2 apply_sql

Databases and their drivers vary a lot when it comes
to apply SQL patches. Some of them are just fine with sending
a blog of SQL to the driver, even when it contains multiple
statements and trigger or procedure, function definitions.

Some of them require a specific implementation.

This is the default implementation that just use the underlying DB
connection to send the patch SQL content.

=cut

sub apply_sql{
    my ($self, $sql) = @_;
    my $dbh = $self->jesp()->get_dbh()->();
    my $ret = $dbh->do( $sql );
    return  defined($ret) ? $ret : confess( $dbh->errstr() );
}


# Shamelessly copied from DBD-mysql-4.043/lib/DBD/mysql.pm
sub _OdbcParse {
    my($class, $dsn, $hash, $args) = @_;
    my($var, $val);
    if (!defined($dsn)) {
        return;
    }
    while (length($dsn)) {
        if ($dsn =~ /([^:;]*\[.*]|[^:;]*)[:;](.*)/) {
            $val = $1;
            $dsn = $2;
            $val =~ s/\[|]//g; # Remove [] if present, the rest of the code prefers plain IPv6 addresses
        } else {
            $val = $dsn;
            $dsn = '';
        }
        if ($val =~ /([^=]*)=(.*)/) {
            $var = $1;
            $val = $2;
            if ($var eq 'hostname'  ||  $var eq 'host') {
                $hash->{'host'} = $val;
            } elsif ($var eq 'db'  ||  $var eq 'dbname') {
                $hash->{'database'} = $val;
            } else {
                $hash->{$var} = $val;
            }
        } else {
            foreach $var (@$args) {
                if (!defined($hash->{$var})) {
                    $hash->{$var} = $val;
                    last;
                }
            }
        }
    }
}

__PACKAGE__->meta()->make_immutable();
