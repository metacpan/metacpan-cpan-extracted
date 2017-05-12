use strict;
use warnings;

package App::PM::Website;
{
  $App::PM::Website::VERSION = '0.131611';
}
#use App::Cmd::Setup -app;
use base 'App::Cmd';

1;


=pod

=head1 NAME

App::PM::Website

=head1 VERSION

version 0.131611

=head1 SYNOPSIS

    # create and initialize configuration file:
    pm-website init --build-dir website \
                    --template-dir template \
                    --config-file config/pm-website.yaml \
                    --username your_username \
                    --groupname monger_long_city_name

    # manually update configfile to list new meeting
    vim config/pm-website.yaml

    # create template directory and templates
    mkdir template/
    cp examples/template/index.in template/
    vim templates/index.in

    # copy cacert for pm.org from examples:
    cp examples/cacert.pem ./

    # render website locally to website/ dir
    pm-website build

    ... view changes locally ...

    # upload website/index file to pm.org
    pm-website upload

=head1 DESCRIPTION

Use C<pm-website> to render and maintain an up-to-date info page
for your Perl Monger group!

L<PM.org|http://pm.org> provides free hosting for perl monger groups.
Pages must be updated with webDAV and server-side scripts are not
allowed.  C<pm-website> will update and install a static, template-driven
page via webDAV with minimal effort.  Spend less time while creating a
more useful front page.  Everyone wins!

=head1 COMMANDS

=over

=item C<pm-website init>

Initialize a configuration yaml file with the necessary keys

=item C<pm-website build>

Builds the index file (F<website/index.html>) by rendering the
template (F<template/index.in>) with TemplateToolkit. The template
is passed models describing the next meeting and location, past
meetings, presenters and locations. See L</Model>.

=item C<pm-website install>

Uploads F<website/index.html> via webDAV to F<< groups.pm.org/groups/I<$groupname> >>, which corresponds to L<< http://I<$groupname>.pm.org/ >>

I<username> and I<groupname> are read from the configuration file
and password is read from the C<groups.pm.org> entry in F<$HOME/.netrc>
if the files exists and is not readable by others.

    #netrc example
    machine  groups.pm.org
    login    USERNAME
    password PASSWORD

=back

=head1 Model

The template will be provided with models derived from the configuration file.  Any information added to the presenter, location and meetings configuration keys will be presented in the model.

=over

=item C<m>

A hash describing the next meeting.

Meetings have additional date keys added from the C<event_date> or C<epoch> field.

=over

=item * C<epoch>

event time in epoch unix seconds.  Created from C<event_date> if missing.

=item * C<dt>

a DateTime object created from C<epoch>

=item * C<ds1>

C<dt> rendered using strp pattern '%Y-%b-%d'.

=item * C<ds_std>

C<dt> rendered using strp pattern '%A %B %e, %Y'.

=item * C<event_date_pretty>

C<dt> rendered using strp pattern '%A the %e' and then munged by Lingua::EN::Numbers::Ordinate to produce strings like "Friday the 13th" or "Thursday the 23rd"

=back

=item C<meetings>

An array of hashes describing past meetings.  The array is reverse sorted by meeting start date. Each hash describes a meeting.  The next meeting C<m> is not included in the list of meetings.

=item C<l>

The location information for the next meeting.

=item C<locations>

hash of location information keyed by location key.

=item C<presenter>

hash of presenter information keyed by presenter id.

=back

=head1 SEE ALSO

=over

=item * L<Template::Toolkit>

=item * la.pm.org: example L<Website|http://la.pm.org> L<Source|https://github.com/spazm/la.pm.org>

=item * L<PM Group Hosting FAQ|http://www.pm.org/faq/hosting_faq.html#www>

=item * L<How to run a successful PM group|http://www.pm.org/successful/>

=back

=head1 AUTHOR

Andrew Grangaard <spazm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Grangaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

#ABSTRACT: Use C<pm-website> to render and maintain an up-to-date info page
for your Perl Monger group!



