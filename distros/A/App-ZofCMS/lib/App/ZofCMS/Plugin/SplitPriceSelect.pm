package App::ZofCMS::Plugin::SplitPriceSelect;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use HTML::Template;

sub _key { 'plug_split_price_select' }
sub _defaults {
    return (
        t_name  => 'plug_split_price_select',
        # prices  => [ qw/foo bar baz/ ],
        options     => 3,
        name        => 'plug_split_price_select',
        id          => 'plug_split_price_select',
        dollar_sign => 1,
    );
}

sub _do {
    my ( $self, $conf, $template, $query, $config ) = @_;

    return
        unless @{ $conf->{prices} || [] };

    my @prices = sort { $a <=> $b } @{ $conf->{prices} };

    @prices = _split_n( $conf->{options}, @prices );

    my $t = HTML::Template->new_scalar_ref( \ _html_template() );

    $t->param(
        name    => $conf->{name},
        id      => $conf->{id},
        options => [
            map +{
                value   => join('-', @{ $prices[ $_ ] }[0,-1]),
                name    => join ' - ',
                    map { $conf->{dollar_sign} ? "\$$_" : $_ }
                        @{ $prices[ $_ ] }[0,-1],
            }, 0 .. $#prices,
        ],
    );

    $template->{t}{ $conf->{t_name} } = $t->output;
}

sub _split_n {
    my $n = shift;
    $n = @_ if @_ < $n;
    my $l = 1 + $#_/$n;
    my @opt = map [splice @_, 0, $l], 1 .. $n;

    for ( reverse 0..$#opt ) {
        unless( @{ $opt[$_] } ) {
            push @{ $opt[$_] }, pop @{ $opt[ $_-1 ] }
        }
    }

    return @opt
}


sub _html_template {
    return <<'END_TEMPLATE';
<select id="<tmpl_var escape='html' name='id'>" name="<tmpl_var escape='html' name='name'>"><tmpl_loop name="options">
        <option value="<tmpl_var escape='html' name='value'>"><tmpl_var escape='html' name='name'></option></tmpl_loop>
</select>
END_TEMPLATE
}


1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::SplitPriceSelect - plugin for generating a <select> for "price range" out of arbitrary range of prices.

=head1 SYNOPSIS

In your Main Config File or ZofCMS Template:

    plugins => [ qw/SplitPriceSelect/ ],

    plug_split_price_select => {
        prices => [ 200, 300, 1000, 4000, 5000 ],
    },

In your L<HTML::Template> file:

    <form...
        <label for="plug_split_price_select">Price range: </label>
        <tmpl_var name='plug_split_price_select'>
    .../form>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that allows you to give several prices and plugin
will create a C<< <select> >> HTML element with its C<< <option> >>s containing I<ranges> of
prices. The idea is that you'd specify how many options you would want to have and plugin will
figure out how to split the prices to generate that many ranges.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/SplitPriceSelect/ ],

You need to add the plugin in the list of plugins to execute.

=head2 C<plug_split_price_select>

    plug_split_price_select => {
        prices      => [ qw/foo bar baz/ ],
        t_name      => 'plug_split_price_select',
        options     => 3,
        name        => 'plug_split_price_select',
        id          => 'plug_split_price_select',
        dollar_sign => 1,
    }

    plug_split_price_select => sub {
        my ( $t, $q, $config ) = @_;
        return {
            prices      => [ qw/foo bar baz/ ],
            t_name      => 'plug_split_price_select',
            options     => 3,
            name        => 'plug_split_price_select',
            id          => 'plug_split_price_select',
            dollar_sign => 1,
        };
    }

The C<plug_split_price_select> first-level key takes a hashref or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_split_price_select> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object. If a certain key
in that hashref is specified in both, Main Config File and ZofCMS Template, then the
value given in ZofCMS Template will take precedence. Plugin will not run if
C<plug_split_price_select> is not specified (or if C<prices> key's arrayref is empty).
Possible keys/value of C<plug_split_price_select> hashref are as follows:

=head3 C<prices>

    prices => [ qw/foo bar baz/ ],

B<Mandatory>. Takes an arrayref as a value, plugin will not run if C<prices> arrayref is
empty or C<prices> is set to C<undef>. The arrayref's elements represent the prices for
which you wish to generate ranges. All elements must be numeric.

=head3 C<options>

    options => 3,

B<Optional>. Takes a positive integer as a value. Specifies how many price ranges (i.e.
C<< <option> >>s) you want to have. B<Note:> if there are not enough prices
in the C<prices> argument, expect to have ranges with the same price on both sides; with
evel smaller dataset, expect to have less than C<options> C<< <option> >>s generated.
B<Defaults to:> C<3>

=head3 C<t_name>

    t_name => 'plug_split_price_select',

B<Optional>. Plugin will put generated C<< <select> >> into C<{t}> ZofCMS Template special key,
the C<t_name> parameter specifies the name of that key. B<Defaults to:>
C<plug_split_price_select>

=head3 C<name>

    name => 'plug_split_price_select',

B<Optional>. Specifies the value of the C<name=""> attribute on the generated C<< <select> >>
element. B<Defaults to:> C<plug_split_price_select>

=head3 C<id>

    id => 'plug_split_price_select',

B<Optional>. Specifies the value of the C<id=""> attribute on the generated C<< <select> >>
element. B<Defaults to:> C<plug_split_price_select>

=head3 C<dollar_sign>

    dollar_sign => 1,

B<Optional>. Takes either true or false values. When set to a true value, the C<< <option> >>s
will contain a dollar sign in front of prices when displayed in the browser (the
C<value="">s will still B<not> contain the dollar sign, see C<PARSING QUERY> section below).
B<Defaults to:> C<1>

=head1 PARSING QUERY

    plug_split_price_select=500-14000

Now, the price ranges are generated and you completed your gorgeous form... how to parse
those ranges is the question. The C<value=""> attribute of each of generated C<< <option> >>
element will contain the starting price in the range followed by a C<-> (dash, rather minus
sign) followed by the ending price in the range. B<Note:> the price on each end of the
range may be the same if there are not enough prices available.
Thus you can do something along the lines of:

    my ( $start_price, $end_price ) = split /-/, $query->{plug_split_price_select};
    my @products_in_which_the_user_is_interested = grep {
        $_->{price} >= $start_price and $_->{price} <= $end_price
    } @all_of_the_products;

=head1 GENERATED HTML CODE

This is what the HTML code generated by the plugin looks like (providing all the optional
arguments are left at their default values):

    <select id="plug_split_price_select" name="plug_split_price_select">
        <option value="200-1000">$200 - $1000</option>
        <option value="4000-6000">$4000 - $6000</option>
        <option value="7000-7000">$7000 - $7000</option>
    </select>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut