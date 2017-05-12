package # don't index this
    HTML::Restricted;
use strict;
use Moo;
use HTML::TreeBuilder 5 '-weak'; # we want weak references

use vars '$VERSION';
$VERSION = '0.06';

=head1 NAME

HTML::Restricted - filter HTML to a set of allowed tags and attributes

=head1 WHY?

This is just a band-aid module I needed while without internet connection.
There also are L<HTML::Strip> and some other modules that should do the
same task and this module will likely vanish again when I review the others
and decide on using one.

L<HTML::StripScripts> seems a likely alternative to this module.

Currently, attributes are not cleaned up. Also, HTML5 tags are simply
stripped as this module doesn't use L<HTML::HTML5::Parser>.

Don't rely on this module.

=cut

use vars qw(%allowed);

%allowed = (
    a      => ['href','name'],
    abbr    => 1,
    address => 1,
    b      => 1,
    blockquote => 1,
    body   => 1,
    br     => 1,
    center => 1,
    code   => 1,
    div    => 1,
    dd     => 1,
    dl    => 1,
    dt    => 1,
    em    => 1,
    font  => 'color',
    form  => 1,
    h1    => 1,
    h2    => 1,
    h3    => 1,
    h4    => 1,
    html  => 1,
    hr    => 1,
    i     => 1,
    img   => ['src'],
    input => 1,
    label  => 1,
    li    => 1,
    ol    => 1,
    option => ['value'],
    p      => 1,
    pre    => 1,
    small  => 1,
    select => 1,
    span   => 1,
    strong => 1,
    table  => 1,
    tbody  => 1,
    td     => 1,
    th     => 1,
    tr     => 1,
    tt     => 1,
    ul     => 1,
);

has tree_class => (
    is => 'rw',
    default => 'HTML::TreeBuilder',
);

#has contents => (
#    is => 'ro',
#    default => sub { +{ %contents } },
#);

has allowed => (
    is => 'ro',
    default => sub { +{ %allowed } },
);

sub filter_element {
    my( $self, $doc, $elt ) = @_;
    if( my $attrs = $self->allowed->{ lc $elt->tag } ) {
        # Strip the attributes except for allowed attributes
        $attrs = [] if ! ref $attrs;
        my %aa = map { $_ => 1 } @$attrs;
        for my $name ($elt->all_external_attr_names) {
            #warn $name;
            $elt->attr($name => undef)
                unless $aa{ lc $name };
        };
        
        # Recurse into children
        for my $child ($elt->content_list) {
            next unless ref $child;
            $self->filter_element($doc, $child);
        };
    #} elsif( $self->contents->{ lc $elt->tag } ) {
    #    # Replace with its contents#

     #   for my $child ($elt->content_list) {
     #       next unless ref $child;
     #       $self->filter_element($doc, $child);
     #   };
     #     
     #   $elt->replace_with($elt->content_list);
    } else {
        print sprintf "%s: removed\n", $elt->tag;
        $elt->delete;
    };
}

sub filter {
    my( $self, $html, %options ) = @_;

    my $t = $options{treebuilder} || do {
        # Load the class
        (my $fn = $self->tree_class) =~ s!::!/!g;
        require "$fn.pm";
        
        $self->tree_class->new;
    };
    
    $t->parse($html || '<html></html>');
    $t->eof;
    
    $t->elementify;
    
    $self->filter_element( $t, $t->root );
    $t
}

1;
