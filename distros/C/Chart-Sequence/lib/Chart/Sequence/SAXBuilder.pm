package Chart::Sequence::SAXBuilder;

$VERSION = 0.000_1;

=head1 NAME

Chart::Sequence::SAXBuilder - Build a Chart::Sequence from XML

=head1 SYNOPSIS

    my $h = Chart::Sqeuence::Builder->new;
    my $h = Chart::Sqeuence::Builder->new(
         Sequence => $prexisting_object
    );

    my $sequences = Pipeline( $h )->parse_file( "foo.seqml" );
    print @$sequences . " found in foo.seqml\n";

=head1 DESCRIPTION

Requires the (otherwise optional) XML::Filter::Dispatcher.

Namespace:

    http://slaysys.com/Chart-Sequence/seqml/0.1

Ignores all elements not in this namespace.  Dies if no <seq:sequence>
element was found (unless a preexisting sequence was passed in).

=cut

use XML::Filter::Dispatcher qw( :xstack xvalue );
@ISA = qw( XML::Filter::Dispatcher );

use strict;
my $ns = "http://slaysys.com/Chart-Sequence/seqml/0.1";

use Chart::Sequence ();
use Chart::Sequence::Node ();
use Chart::Sequence::Message ();

sub new {
    my $proto = shift;
    my %options = @_;

    $proto->SUPER::new( 
        Namespaces => { "seq" => $ns },
        Rules => [
            "seq:*" => [ "string()" => sub { xset } ],   # set data members
            "seq:*[*]"              => sub {
                die "Unrecognized SeqML element <$_[1]->{Name}>\n";
            },
            "seq:sequence"    => sub { xadd(
                $options{Sequence} || Chart::Sequence->new
            )},
            "seq:node"       => sub {
                xadd( nodes => Chart::Sequence::Node->new )
            },
            "seq:message"     => sub {
                xadd( messages => Chart::Sequence::Message->new )
            },
            "start-document::*"     => sub { xpush []; }, # ARRAY to hold seqs
            "/end-document::*"     => sub {  xpop; }, # return ARRAY of seqs
        ],
    );
}

1;

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
