package Dancer::Plugin::Piwik;

use 5.010001;
use strict;
use warnings FATAL => 'all';
use Dancer qw/:syntax/;
use Dancer::Plugin;

=head1 NAME

Dancer::Plugin::Piwik - Generate JS code for Piwik

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

# on loading, spam the message if disabled

if (plugin_setting->{url} && plugin_setting->{id}) {
    info "Loading Piwiki plugin";
}
else {
    warning "Missing url and id for Piwiki, plugin is disabled";
}

=head1 SYNOPSIS

In your configuration:

  plugins:
    Piwik:
      id: "your-id"
      url: "your-url"
      username_session_key: 'piwik_username'

The username_session_key is optional. If set, the plugin will look
into the session value for the given key and set that as the tracked
username. You probably want to that in an hook.


In your module

    use Dancer ':syntax';
    use Dancer::Plugin::Piwik;

    # if use'ing Dancer::Plugin::Auth::Extensible;
    hook before => sub {
        if (my $user = logged_in_user) {
            session(piwik_username => $user->username);
        }
        else {
            session(piwik_username => undef);
        }
    }

=head1 CONFIGURATION

Two keys are required:

=head2 id

The numeric id of the tracked site (you find it in the Piwik admin).

=head2 url

The url of the tracking site, B<without protocol> and B<without
trailing slash>. E.g.

 mysite.org/stats

=head1 EXPORTED KEYWORDS

All the following keywords support the boolean argument C<ajax>.
Instead of the javascript, a perl structure will be returned.

=head2 piwik

Return generic code for page view tracking. No argument required.

=head2 piwik_category(category => "name")

Generate js for category pages. Requires a named argument C<category>
with the name of the category to track.

=head2 piwik_view(product => { sku => $sku, description => $desc, categories => \@categories, price => $price  })

Generate js for flypages. Expects a named argument product, paired
with an hashref with the product data, having the following keys

=over 4

=item sku

=item description

=item categories

(an arrayref with the names of the categories). An empty arrayref can
do as well).

=item price

The price of the item

=back

=head2 piwik_cart(cart => \@items, subtotal => $subtotal)

Generate js for cart view. Requires two named arguments. The C<cart>
argument must point to an arrayref of hashref products, with the same
keys of C<piwik_view>, and an additional key C<quantity>.

=cut

sub _piwik {
    my %args = @_;
    return _generate_js($args{ajax});
}

sub _piwik_category {
    my %args = @_;
    my $category = $args{category};
    unless ($category) {
        return _generate_js($args{ajax});
    }
    return _generate_js($args{ajax}, [ setEcommerceView => \0, \0, $category  ]);
}

=head2 piwik_search(search => { query => 'query', category => 'category', matches => 10 }};

Generate js for search results. Requires a C<search> argument with the
data to pass to piwik. The only mandatory value is C<query>.

=cut

sub _piwik_search {
    my %args = @_;
    my $search = $args{search};
    unless ($search and (ref($search) eq 'HASH') and $search->{query}) {
        return _generate_js($args{ajax});
    }
    my $category = $search->{category} || \0;
    my $query = $search->{query};
    my $matches = defined($search->{matches}) ? $search->{matches} : \0;
    return _generate_js($args{ajax}, [ trackSiteSearch => $query, $category, $matches ]);
}


sub _piwik_view {
    my %args = @_;
    my $product = $args{product};
    unless ($product) {
        return _generate_js($args{ajax});
    }
    my $arg = [
               setEcommerceView => $product->{sku},
               $product->{description},
               [ @{ $product->{categories} } ],
               $product->{price} + 0,
              ];
    return _generate_js($args{ajax}, $arg);
}

sub _piwik_cart {
    my %args = @_;
    my $subtotal = $args{subtotal};
    my $cart = $args{cart};
    unless ($cart && defined($subtotal)) {
        return _generate_js($args{ajax});
    }
    my @addendum = _unroll_cart($cart);
    push @addendum, [ trackEcommerceCartUpdate => $subtotal + 0 ];
    return _generate_js($args{ajax}, @addendum);
}

sub _unroll_cart {
    my $cart = shift;
    my @addendum;
    foreach my $item (@$cart) {
        push @addendum, [
                         addEcommerceItem => $item->{sku},
                         $item->{description},
                         [ @{ $item->{categories} } ],
                         $item->{price} + 0,
                         $item->{quantity} + 0,
                        ];
    }
    return @addendum;
}

=head2 piwik_order(cart => \@items, order => { order_number => $id, total_cost => $total, subtotal => $subtotal, taxes => $taxes, shipping => $shipping, discount => $discount }

Generate js for the receipt. Two required arguments: C<cart> is the
same as C<piwik_cart>, while order is an hashref with the following keys:

=over 4

=item order_number (required)

=item total_cost (required)

=item subtotal (optional)

=item taxes (optional)

=item shipping (optional)

=item discount (optional)

=back

=cut

sub _piwik_order {
    my %args = @_;
    my $cart = $args{cart};
    my $order = $args{order};
    unless ($cart && $order) {
        return _generate_js($args{ajax});
    }
    my @addendum = _unroll_cart($cart);
    my @missing;
    foreach my $i (qw/total_cost order_number/) {
        push @missing, $i unless defined $order->{$i};
    }
    if (@missing) {
        warning "Missing order keys: " . join(' ', @missing);
        return _generate_js($args{ajax});
    }

    # avoid touching the original
    $order = { %$order };

    foreach my $i (qw/subtotal taxes shipping discount/) {
        if (defined $order->{$i}) {
            # coerce it to a number
            $order->{$i} += 0;
        }
        else {
            # set it to false
            $order->{$i} = \0;
        }
    }
    push @addendum, [trackEcommerceOrder => $order->{order_number} .'',
                     $order->{total_cost} + 0,
                     $order->{subtotal},
                     $order->{taxes},
                     $order->{shipping},
                     $order->{discount},
                    ];
    return _generate_js($args{ajax}, @addendum);
}

sub _generate_js {
    my ($ajax, @args) = @_;
    my $piwik_url = plugin_setting->{url};
    my $piwik_id  = plugin_setting->{id};
    unless ($piwik_url && defined($piwik_id)) {
        $ajax ? return {} : return '';
    }
    if (my $session_key = plugin_setting->{username_session_key}) {
        if (my $username = session($session_key)) {
            push @args, [ setUserId => $username ];
        }
    }
    unless (scalar(grep { ref($_) eq 'ARRAY' and $_->[0] eq 'trackSiteSearch' } @args)) {
        push @args, ['trackPageView'];
    }
    push @args, ['enableLinkTracking'];
    if ($ajax) {
        return {
                piwik_url => $piwik_url,
                piwik_id => $piwik_id,
                elements => \@args,
               };
    }
    my $addendum = '';
    foreach my $arg (@args) {
        $addendum .= '_paq.push(' . to_json($arg) . ");\n";
    }

    my $js = <<"JAVASCRIPT";
<script type="text/javascript">
  var _paq = _paq || [];
  $addendum
  (function() {
    var u=(("https:" == document.location.protocol) ? "https" : "http") + "://$piwik_url/";
    _paq.push(['setTrackerUrl', u+'piwik.php']);
    _paq.push(['setSiteId', $piwik_id ]);
    var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0]; g.type='text/javascript';
    g.defer=true; g.async=true; g.src=u+'piwik.js'; s.parentNode.insertBefore(g,s);
  })();
</script>
<noscript><p><img src="http://$piwik_url/piwik.php?idsite=$piwik_id" style="border:0;" alt="" /></p></noscript>
JAVASCRIPT
        return $js;
}

register piwik => \&_piwik;
register piwik_category => \&_piwik_category;
register piwik_view => \&_piwik_view;
register piwik_cart => \&_piwik_cart;
register piwik_order => \&_piwik_order;
register piwik_search => \&_piwik_search;

register_plugin;


=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-piwik at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Piwik>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Piwik


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Piwik>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Piwik>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Piwik>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Piwik/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Dancer::Plugin::Piwik
