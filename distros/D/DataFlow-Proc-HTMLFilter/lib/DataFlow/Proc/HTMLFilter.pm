package DataFlow::Proc::HTMLFilter;

use strict;
use warnings;

# ABSTRACT: A HTML filtering processor

our $VERSION = '1.112100';    # VERSION

use Moose;
extends 'DataFlow::Proc';

use namespace::autoclean;

use HTML::TreeBuilder::XPath;
use MooseX::Aliases;
use Moose::Util::TypeConstraints 1.01;

enum 'HTMLFilterTypes', [qw(NODE HTML VALUE)];

has 'search_xpath' => (
    'is'       => 'ro',
    'isa'      => 'Str',
    'required' => 1,
    'alias'    => 'xpath',
);

has 'result_type' => (
    'is'      => 'ro',
    'isa'     => 'HTMLFilterTypes',
    'default' => 'HTML',
    'alias'   => 'type',
);

has 'ref_result' => (
    'is'      => 'ro',
    'isa'     => 'Bool',
    'default' => 0,
);

has 'nochomp' => (
    'is'      => 'ro',
    'isa'     => 'Bool',
    'default' => 0,
);

sub _build_p {
    my $self = shift;

    my $proc = sub {
        my $html = HTML::TreeBuilder::XPath->new_from_content($_);

        #warn 'xpath is built';
        #warn 'values if VALUES';
        return $html->findvalues( $self->search_xpath )
          if $self->result_type eq 'VALUE';

        #warn 'not values, find nodes';
        my @result = $html->findnodes( $self->search_xpath );

        #use Data::Dumper; warn 'result = '.Dumper(\@result);
        return () unless @result;
        return @result if $self->result_type eq 'NODE';

        #warn 'wants HTML';
        return map { $_->as_HTML } @result;
    };

    #my $proc2 = $self->nochomp ? $proc : sub { return chomp $proc->(@_) };
    #my $proc3 = $self->ref_result ? sub { return [ $proc2->(@_) ] } : $proc2;

    return $self->ref_result ? sub { return [ $proc->(@_) ] } : $proc;
}

__PACKAGE__->meta->make_immutable;

1;



=pod

=encoding utf-8

=head1 NAME

DataFlow::Proc::HTMLFilter - A HTML filtering processor

=head1 VERSION

version 1.112100

=head1 SYNOPSIS

    use DataFlow::Proc::HTMLFilter;

    my $filter_html = DataFlow::Proc::HTMLFilter->new(
        search_xpath => '//td',
    	result_type  => 'HTML',
	);

    my $filter_value = DataFlow::Proc::HTMLFilter->new(
        search_xpath => '//td',
    	result_type  => 'VALUE',
	);

    my $input = <<EOM;
    <html><body>
      <table>
        <tr><td>Line 1</td><td>L1, Column 2</td>
        <tr><td>Line 2</td><td>L2, Column 2</td>
      </table>
    </html></body>
    EOM

    $filter_html->process( $input );
    # @result == '<td>Line 1</td>', ... '<td>L2, Column 2</td>'

    $filter_value->process( $input );
    # @result == q{Line 1}, ... q{L2, Column 2}

=head1 DESCRIPTION

This processor type provides a filter for HTML content.
Each item will be considered as a HTML content and will be filtered
using L<HTML::TreeBuilder::XPath>.

=head1 ATTRIBUTES

=head2 search_xpath

This attribute is a XPath string used to filter down the HTML content.
The C<search_xpath> attribute is mandatory.

=head2 result_type

This attribute is a string, but its value B<must> be one of:
C<HTML>, C<VALUE>, C<NODE>. The default is C<HTML>.

=over 4

=item *

HTML

The result will be the HTML content specified by C<search_xpath>.

=item *

VALUE

The result will be the literal value enclosed by the tag and/or attribute
specified by C<search_xpath>.

=item *

NODE

The result will be a list of L<HTML::Element> objects, as returned by the
C<findnodes> method of L<HTML::TreeBuilder::XPath> class.

=back

Most people will probably use C<HTML> or C<VALUE>, but this option is also
provided in case someone wants to manipulate the HTML elements directly.

=head2 ref_result

This attribute is a boolean, and it signals whether the result list should be
added as a list of items to the output queue, or as a reference to an array
of items. The default is 0 (false).

There is a semantic subtlety here: if C<ref_result> is 1 (true),
then one HTML item (input) may generate one or zero ArrayRef item (output),
i.e. it is a one-to-one mapping.
On the other hand, by keeping C<ref_result> as 0 (false), one HTML item
may produce any number of items as result,
i.e. it is a one-to-many mapping.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc DataFlow::Proc::HTMLFilter

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/DataFlow-Proc-HTMLFilter>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annonations of Perl module documentation.

L<http://annocpan.org/dist/DataFlow-Proc-HTMLFilter>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/DataFlow-Proc-HTMLFilter>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/DataFlow-Proc-HTMLFilter>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/DataFlow-Proc-HTMLFilter>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/DataFlow-Proc-HTMLFilter>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual way to determine what Perls/platforms PASSed for a distribution.

L<http://matrix.cpantesters.org/?dist=DataFlow-Proc-HTMLFilter>

=back

=head2 Email

You can email the author of this module at C<RUSSOZ at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #sao-paulo.pm then talk to this person for help: russoz.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dataflow-proc-htmlfilter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DataFlow-Proc-HTMLFilter>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/russoz/DataFlow-Proc-HTMLFilter>

  git clone https://github.com/russoz/DataFlow-Proc-HTMLFilter

=head1 AUTHOR

Alexei Znamensky <russoz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alexei Znamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

