package App::PAIA::Command::change;
use strict;
use v5.10;
use parent 'App::PAIA::Command';

our $VERSION = '0.30';

sub _execute {
    my ($self, $opt, $args) = @_;

    my $auth = $self->auth // $self->usage_error("missing PAIA auth URL");

    my %params = (
        patron       => $self->patron,
        username     => $self->username,
        old_password => $self->password,
    );

    $self->auto_login_for('change');

    # Password should not be given as command line option, but as input
    # TODO: better way to get a new password, without echoing
    # e.g. use Term::ReadKey (ReadMode('noecho')) or TermTerm::ReadPassword
    #  See also App::Cmd::Plugin::Prompt or Term::ReadPassword
    {
        print "new password: ";
        chomp(my $pwd = scalar <STDIN>);
        if (length($pwd) < 4) {
            say "your password is too short!";
            redo;
        } else {
            print "please repeat: ";
            chomp(my $pwd2 = scalar <STDIN>);
            if ($pwd2 ne $pwd) {
                say "passwords don't match!"; 
                redo;
            }
        }
        $params{new_password} = $pwd;
    }
     
    $self->request( "POST", "$auth/change", \%params ); 
}

1;
__END__

=head1 NAME

App::PAIA::Command::change - change login password

=cut
