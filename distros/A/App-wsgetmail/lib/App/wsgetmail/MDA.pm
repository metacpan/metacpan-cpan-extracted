# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 2020-2022 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}

=head1 NAME

App::wsgetmail::MDA - Deliver mail to another command's standard input

=head1 SYNOPSIS

    my $mda = App::wsgetmail::MDA->new({
      command => "/opt/rt5/bin/rt-mailgate",
      command_args => "--url https://rt.example.com --queue General --action correspond",
      command_timeout => 15,
      debug => 0,
    })
    $mda->forward($message, $message_path);

=head1 DESCRIPTION

App::wsgetmail::MDA takes mail fetched from web services and routes it to
another command via standard input.

=cut

package App::wsgetmail::MDA;
use Moo;

use IPC::Run qw( run timeout );

=head1 ATTRIBUTES

You can initialize a new App::wsgetmail::MDA object with the attributes
below. C<command> and C<command_args> are required; the rest are
optional. All attributes are read-only.

=head2 command

A string with the executable to run. You can specify an absolute path, or a
plain command name which will be found from C<$PATH>.

=cut

has command => (
    is => 'ro',
    required => 1,
);

=head2 command_args

A string with additional arguments to call C<command> with. These arguments
follow shell quoting rules: you can escape characters with a backslash, and
denote a single string argument with single or double quotes.

=cut

has command_args => (
    is => 'ro',
    required => 1,
);

=head2 command_timeout

A number. The run command will be terminated if it takes longer than this many
seconds.

=cut

has command_timeout => (
    is => 'ro',
    default => sub { 30; }
);

# extension and recipient are currently unused. See pod below.
has extension => (
    is => 'ro',
    required => 0
);

has recipient => (
    is => 'ro',
    required => 0,
);

=head2 debug

A boolean. If true, the object will issue additional diagnostic warnings if it
encounters any trouble.

=head2 Unused Attributes

These attributes were used in previous versions of the module. They are
currently unimplemented and always return undef. You cannot initialize them.

=over 4

=item * extension

=item * recipient

=back

=cut

has debug => (
    is => 'ro',
    default => sub { 0 }
);



my @config_fields = qw( command command_args command_timeout debug );
around BUILDARGS => sub {
    my ( $orig, $class, $config ) = @_;
    my $attributes = { map { $_ => $config->{$_} } @config_fields };
    return $class->$orig($attributes);
};


=head1 METHODS

=head2 forward($message, $filename)

Invokes the configured command to deliver the given message. C<$message> is
an object like L<App::wsgetmail::MS365::Message>. C<$filename> is the path
to a file with the raw message content.

=cut

sub forward {
    my ($self, $message, $filename) = @_;
    return $self->_run_command($filename);
}


sub _run_command {
    my ($self, $filename) = @_;
    open my $fh, "<$filename"  or die $!;
    my ($input, $output, $error);
    unless ($self->command) {
        warn "no action to delivery message, command option is empty or null" if ($self->debug);
        return 1;
    }
    my $ok = run ([ $self->command, _split_command_args($self->command_args, 1)], $fh, \$output, \$error, timeout( $self->command_timeout + 5 ) );
    unless ($ok) {
        warn sprintf('failed to run command "%s %s" for file %s : %s',
                     $self->command,
                     ($self->debug ? join(' ', _split_command_args($self->command_args)) : '' ),
                     $filename, $?);
        warn "output : $output\nerror:$error\n" if ($self->debug);
    }
    close $fh;
    return $ok;
}


#TODO: make into a simple cpan module
# Loosely based on https://metacpan.org/pod/Parse::CommandLine
sub _split_command_args {
    my ($line, $strip_quotes) = @_;

    # strip leading/trailing spaces
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    my (@args, $quoted, $escape_next, $next_arg);
    foreach my $character (split('', $line) ) {
        if ($escape_next) {
            $next_arg .= $character;
            $escape_next = undef;
            next;
        }

        if ($character =~ m|\\|) {
            $next_arg .= $character;
            if ($quoted) {
                $escape_next = 1;
            }
            next;
        }

        if ($character =~ m/\s/) {
            if ($quoted) {
                $next_arg .= $character;
            }
            else {
                push @args, $next_arg if defined $next_arg;
                undef $next_arg;
            }
            next;
        }

        if ($character =~ m/['"]/) {
            if ($quoted) {
                if ($character eq $quoted) {
                    $quoted = undef;
                    $next_arg .= $character unless ($strip_quotes);
                } else {
                    $next_arg .= $character;
                }
            }
            else {
                $quoted = $character;
                $next_arg .= $character unless ($strip_quotes);
            }
            next;
        }
        $next_arg .= $character;
    }
    push @args, $next_arg if defined $next_arg;
    return @args;
}

=head1 AUTHOR

Best Practical Solutions, LLC <modules@bestpractical.com>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2015-2020 by Best Practical Solutions, LLC.

This is free software, licensed under:

The GNU General Public License, Version 2, June 1991

=cut

1;
