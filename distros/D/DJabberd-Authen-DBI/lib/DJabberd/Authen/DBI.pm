package DJabberd::Authen::DBI;
use strict;
use warnings;
use base 'DJabberd::Authen';

use Digest::MD5 qw(md5_hex md5_base64);
use Digest::SHA1 qw(sha1_hex sha1_base64);
use DJabberd::Log;
our $logger = DJabberd::Log->get_logger;
use DBI;

our $VERSION = '0.2';

sub log {
    $logger;
}

# configuration loading
BEGIN {
    no strict 'refs';
    for my $name qw(dsn user pass query args) {
        *{"set_config_".$name} = sub {
            my $self = shift;
            $self->{$name} = shift if @_;
            $self->{$name};
        }
    }
}

sub blocking { 1; }
sub can_register_jids { 0; }
sub can_unregister_jids { 0; }
sub can_retrieve_cleartext { 0; }

# finalize configuration
sub finalize {
    my $self = shift;

    die 'No database configured.' unless $self->{dsn};
    die 'No query specified.' unless $self->{query};

    $self->{dbi} = DBI->connect(map { $self->{$_} } qw(dsn user pass))
      or die 'Error connectin to the database. '.$DBI::errstr;
    $logger->debug('Connected to database '.$self->{dsn});

    $self->{sth} = $self->{dbi}->prepare($self->{query})
      or die 'Error preparing statement. '.$self->{dbi}->errstr;
    $logger->debug('Query prepared '.$self->{dsn});

}

sub check_cleartext {
    my ($self, $cb, %args) = @_;
    my $username = $args{username};
    my $password = $args{password};
    my $conn = $args{conn};
    unless ($username =~ /^\w+$/) {
        $cb->reject;
        return;
    }

    my %arguments =
      ( login => $username,
        password => $password,
        password_sha1_hex => sha1_hex($password),
        password_sha1_base64 => sha1_base64($password),
        password_md5_hex => md5_hex($password),
        password_md5_base64 => md5_base64($password) );

    $self->{sth}->execute
      ( map { $arguments{$_} } split /,/, $self->{args} )
        or do {
            $logger->debug('Error Executing query '.$self->{dbi}->errstr);
            $cb->reject();
            return
        };

    if (my ($data) = $self->{sth}->fetchrow_array) {
        $logger->debug('User '.$username.' authenticated');
        $cb->accept();
    } else {
        $logger->debug('Failed authentication for user '.$username);
        $cb->reject();
    }

}

1;

__END__

=head1 NAME

DJabberd::Authen::DBI - Check users and passwords using a simple sql query

=head1 SYNOPSIS

    <VHost mydomain.com>

        [...]

        <Plugin DJabberd::Authen::DBI>
            dsn     dbi:Pg:dbname=foo
            user    foo
            pass    bar
            query   SELECT * FROM user WHERE login=? AND password=?
            args    login,password
        </Plugin>
    </VHost>

=head1 DESCRIPTION

This module implements the "check_cleartext" method of the Authen
module in DJabberd. Your database schema should support checking the
credentials in one query.

=head1 CONFIGURATION

The following keys are used in the configuration.

=over

=item dsn

This is the DBI data source string, first parameter to
DBI->connect. This option is mandatory.

=item user

The database user name, second parameter to DBI->connect.

=item pass

The database password, third parameter to DBI->connect.

=item query

The SQL query that will be prepared for each authentication. You
should use the standard placeholder mark (?) to send the arguments.
The connection will be accepted if this query returns at least one
row and will be rejected if no rows are returned.

=item args

This allows you to define the order of the arguments for your prepared
statement. You can even use an argument more than once. The following
keys are accepted and will be replaced by the correct value: login,
password, password_sha1_hex, password_sha1_base64, password_md5_hex,
password_md5_base64.

=back

=head1 BUGS

If you find any bug, please contact the author.

=head1 COPYRIGHT

This module was created by "Daniel Ruoso" <daniel@ruoso.com>.
It is licensed under both the GNU GPL and the Artistic License.

=cut

