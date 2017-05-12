package ActiveResource;
our $VERSION = "0.01";
1;

__END__

=head1 ActiveResource

ActiveResource - Implemented in Perl.

=head1 VERSION

This document describes ActiveResource version 0.01

=head1 SYNOPSIS

    # A class for redmine issue
    package Issue;
    use  parent 'ActiveResource::Base';
    __PACKAGE__->site("http://localhost:3000");
    __PACKAGE__->user("admin");
    __PACKAGE__->password("admin");

    package main;

    # Find existing ticket
    my $issue = Issue->find(42);

    # Create
    my $issue = Issue->create(
        project_id => 1,
        subject => "OHAI",
        description => "Lipsum"
    );

    # Update
    $issue->description("Updated Lipsum");
    $issue->save;

=head1 DESCRIPTION

ActiveResource is a set REST API that was defined in Ruby on Rails
project, and this the implementation in Perl that can talk to any
Rails server that supports it.

To use this api, you MUST name you you classes the same as model
names.  For example, redmine system provide REST api for therir
projects and issues, and they named them "projects" and "issues". To
talk to them with ActiveResource, we must defind two classes:

    package Project;
    use parent 'ActiveResource::Base';

    package Issue;
    use parent 'ActiveResource::Base';

It is planed to be make the model name configurable in the future
releases.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
