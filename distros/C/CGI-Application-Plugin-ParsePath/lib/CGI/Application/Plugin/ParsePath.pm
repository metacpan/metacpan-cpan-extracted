package CGI::Application::Plugin::ParsePath;

use warnings;
use strict;

=head1 NAME

CGI::Application::Plugin::ParsePath - populate query parameters by parsing the
PATH_INFO

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our $DEBUG=0;

sub import {
    my $caller = scalar(caller);
    $caller->add_callback(prerun => \&_parse_path);
    goto &Exporter::import;
}

=head1 SYNOPSIS

This module populates the CGI query parameters based on the query path.
It shamelessly steals the PATH_INFO parsing method from Michael
Peters' CGI::Application::Dispatch.

Because the query parameters rather than the application
parameters are populated, modules like
CGI::Application::Plugin::ValidateRM are supported.

In your webapp.pl instance script:

    use My::Blog;

    # Supply a table that specifies rules for parsing the PATH.
    # Basically, we loop through each line stopping at the first rule
    # that matches. Path element definitions that preceded by colons
    # populate CGI query parameters with the same name. In the case
    # where an element name is followed by a question mark, the
    # parameter is optional.

    my $webapp = My::Blog->new(
        PARAMS => {
            'table' => = [
                ''                         => {rm => 'recent'},
                'posts/:category'          => {rm => 'posts' },
                'date/:year/:month?/:day?' => {
                    rm          => 'by_date',
                },
                '/:rm/:id'             => { },
            ];
        }
    );
    $webapp->run();

    # Examples
    # QUERY PATH: webapp.pl/
    # QUERY PARAMS: rm = recent

    # QUERY PATH: webapp.pl/posts/3
    # QUERY PARAMS: rm = posts, category = 3

    # QUERY PATH: webapp.pl/date/2004/12/02
    # QUERY PARAMS: rm = by_date, year = 2004, month = 12, day = 02

    # QUERY PATH: webapp.pl/edit/1234
    # QUERY PARAMS: rm = edit, id = 1234

In your application module simply include the plugin:

    use CGI::Application::Plugin::ParsePath;

=cut

# We allow for mod_perl here, but we need to populate the mp query
# parameters in _parse)path
sub _http_method { $ENV{HTTP_REQUEST_METHOD}; }

# This is Michael Peters path parser from CGI::Application::Dispatch
sub _parse_path {
    my $self = shift;
    my $path = $ENV{PATH_INFO};
    my $table = $self->param('table');
    $path .='/' unless substr($path, -1, 1) eq '/';

    # get the module name from the table
    return unless defined($path);

    unless (ref($table) eq 'ARRAY' ) {
        warn "[Dispatch] Invalid or no dispatch table!\n";
        return;
    }

    # look at each rule and stop when we get a match
    for ( my $i = 0 ; $i < scalar(@$table) ; $i += 2 ) {
        my $rule = $table->[$i];

        # are we trying to dispatch based on HTTP_METHOD?
        my $http_method_regex = qr/\[([^\]]+)\]$/;
        if( $rule =~ /$http_method_regex/ ) {
            my $http_method = $1;
            # go ahead to the next rule
            next unless lc($1) eq lc(_http_method);
            # remove the method portion from the rule
            $rule =~ s/$http_method_regex//;
        }

        # make sure they start and end with a '/' to match how PATH_INFO is formatted
        $rule = "/$rule" unless ( index( $rule, '/' ) == 0 );
        $rule = "$rule/" if ( substr( $rule, -1 ) ne '/' );

        my @names = ();

        # translate the rule into a regular expression, but remember where the named args are
        # '/:foo' will become '/([^\/]*)'
        # and
        # '/:bar?' will become '/?([^\/]*)?'
        # and then remember which position it matches

        $rule =~ s{
            (^|/)                 # beginning or a /
            (:([^/\?]+)(\?)?)     # stuff in between
        }{
            push(@names, $3);
            $1 . ($4 ? '?([^/]*)?' : '([^/]*)')
        }gxe;

        # '/*/' will become '/(.*)/$' the end / is added to the end of
        # both $rule and $path elsewhere
        if($rule =~ m{/\*/$}) {
          $rule =~ s{/\*/$}{/(.*)/\$};
          push(@names,'dispatch_url_remainder');
        }

        warn "[Dispatch] Trying to match '${path}' against rule '$table->[$i]' using regex '${rule}'\n"
			if $DEBUG;

        # if we found a match, then run with it
        if ( my @values = ( $path =~ m#^$rule$# ) ) {

            warn "[Dispatch] Matched!\n" if $DEBUG;

            my %named_args = %{ $table->[ ++$i ] };
            @named_args{@names} = @values  if @names;

            # Populate the Query parameters. Need a solution for
            # mod_perl too
            my $q = $self->query;
            my $rm_key = $self->mode_param;
            foreach my $param (%named_args) {
                if ($param eq $rm_key) {
                    $self->prerun_mode($named_args{$param});  
                }
                $q->param($param, $named_args{$param});
            }
        }
    }

    return;
}


=head1 AUTHOR

Dan Horne, C<< <dhorne at cpan.org> >>, largely based on code by
Michael Peters C<< <mpeters@plusthree.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-parsepath at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-ParsePath>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::ParsePath

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-ParsePath>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-ParsePath>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-ParsePath>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-ParsePath>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Michael Peters & Dan Horne, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CGI::Application::Plugin::ParsePath
