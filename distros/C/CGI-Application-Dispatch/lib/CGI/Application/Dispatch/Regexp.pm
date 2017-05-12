package CGI::Application::Dispatch::Regexp;
use strict;
use base 'CGI::Application::Dispatch';

our $VERSION = '3.04';

=pod

=head1 NAME

CGI::Application::Dispatch::Regexp - Dispatch requests to
CGI::Application based objects using regular expressions

=head1 SYNOPSIS

    use CGI::Application::Dispatch::Regexp;

    CGI::Application::Dispatch::Regexp->dispatch(
        prefix  => 'MyApp',
        table   => [
            ''                                    => { app => 'Welcome',
                                                       rm  => 'start',
                                                     },
            qr|/([^/]+)/?|                        => { names => ['app'],
                                                     },
            qr|/([^/]+)/([^/]+)/?|                => { names =>
                                                         [qw(app rm)]
                                                     },
            qr|/([^/]+)/([^/]+)/page(\d+)\.html?| => { names =>
                                                         [qw(app rm page)]
                                                     },
        ],
    );


=head1 DESCRIPTION

L<CGI::Application::Dispatch> uses its own syntax dispatch table.
C<CGI::Application::Dispatch::Regexp> allows one to use flexible and
powerful Perl regular expressions to transform a path into argument
list.

=head1 DISPATCH TABLE

The dispatch table should contain list of regular expressions with hashref of
corresponding parameters. Hash element 'names' is a list of names of regular
expression groups. The default table looks like this:

        table       => [
            qr|/([^/]+)/?|          => { names => ['app']      },
            qr|/([^/]+)/([^/]+)/?|  => { names => [qw(app rm)] },
        ],

Here's an example of defining a custom 'page' parameter:

        qr|/([^/]+)/([^/]+)/page(\d+)\.html/?| => {
            names => [qw(app rm page)],
        },


=head1 COPYRIGHT & LICENSE

Copyright Michael Peters and Mark Stosberg 2008, all rights reserved. 

=head1 SEE ALSO

L<CGI::Application>, L<CGI::Application::Dispatch>


=cut

# protected method - designed to be used by sub classes, not by end users
sub _parse_path {
    my ($self, $path, $table) = @_;

    # get the module name from the table
    return unless defined($path);

    unless(ref($table) eq 'ARRAY') {
        warn "Invalid or no dispatch table!\n";
        return;
    }

    for(my $i = 0 ; $i < scalar(@$table) ; $i += 2) {

        # translate the rule into a regular expression, but remember
        # where the named args are
        my $rule = $table->[$i];

        warn
          "[Dispatch::Regexp] Trying to match '$path' against rule '$table->[$i]' using regex '$rule'\n"
          if $CGI::Application::Dispatch::DEBUG;

        # if we found a match, then run with it
        if(my @values = ($path =~ m|^$rule$|)) {

            warn "[Dispatch::Regexp] Matched!\n" if $CGI::Application::Dispatch::DEBUG;

            my %named_args = %{$table->[++$i]};
            my $names      = delete($named_args{names});

            @named_args{@$names} = @values if(ref($names) eq 'ARRAY');

            return \%named_args;

        }

    }

    return;
}

sub dispatch_args {
    my ($self, $args) = @_;
    return {
        default     => ($args->{default}     || ''),
        prefix      => ($args->{prefix}      || ''),
        args_to_new => ($args->{args_to_new} || {}),

        table => [
            qr|/([^/]+)/?|         => {names => ['app']},
            qr|/([^/]+)/([^/]+)/?| => {names => [qw(app rm)]},
        ],

    };
}

1;
