package DBIx::Class::InflateColumn::Currency;
use strict;
use warnings;
our $VERSION = '0.02005';

BEGIN {
    use base qw/DBIx::Class Class::Accessor::Grouped/;
    __PACKAGE__->mk_group_accessors('inherited', qw/
        currency_class currency_code currency_format currency_code_column
    /);
};

__PACKAGE__->currency_class('Data::Currency');

sub register_column {
    my ($self, $column, $info, @rest) = @_;
    $self->next::method($column, $info, @rest);

    return unless defined $info->{'is_currency'};

    my $currency_class = $info->{'currency_class'} || $self->currency_class || 'Data::Currency';
    my $currency_code =  $info->{'currency_code'} || $self->currency_code;
    my $currency_code_column = $info->{'currency_code_column'} || $self->currency_code_column;
    my $currency_format = $info->{'currency_format'} || $self->currency_format;

    eval "use $currency_class";
    $self->throw_exception("Error loading $currency_class: $@") if $@;

    $self->inflate_column(
        $column => {
            inflate => sub {
                my ($value, $obj) = @_;
                my $code = $currency_code_column ?
                    $obj->$currency_code_column || $currency_code :
                    $currency_code;

                return $currency_class->new($value, $code, $currency_format);
            },
            deflate => sub {
                return shift->value;
            },
        }
    );
};

1;
__END__

=head1 NAME

DBIx::Class::InflateColumn::Currency - Auto-create Data::Currency objects from columns.

=head1 SYNOPSIS

Load this component and then declare one or more columns as currency columns.

    package Item;
    __PACKAGE__->load_components(qw/InflateColumn::Currency/);
    __PACKAGE__->add_columns(
        price => {
            data_type      => 'decimal',
            size           => [9,2],
            is_nullable    => 0,
            default_value  => '0.00',
            is_currency    => 1
        }
    );

Then you can treat the specified column as a Data::Currency object.

    print 'US Dollars: ', $item->price;
    print 'Japanese Yen: ', $item->price->convert('JPY');

=head1 DESCRIPTION

This module inflates/deflates designated columns into Data::Currency objects.

=head1 METHODS

=head2 currency_code

=over

=item Arguments: $code

=back

Gets/sets the default currency code used when inflating currency columns.

    __PACKAGE__->currency_code('USD');

You can also set this on a per column basis:

    __PACKAGE__->add_columns(
        price => {
            data_type      => 'decimal',
            size           => [9,2],
            is_nullable    => 0,
            default_value  => '0.00',
            is_currency    => 1,
            currency_code  => 'USD'
        }
    );

=head2 currency_code_column

=over

=item Arguments: $name

=back

Gets/sets the name of the column where the current rows currency code is stored.

    __PACKAGE__->currency_code_column('my_code_column');

When set, the currency object will inherit its code from the value in this
column. If the column is undefined/empty, C<currency_code> will be used instead.

You can also set this on a per column basis:

    __PACKAGE__->add_columns(
        price => {
            data_type             => 'decimal',
            size                  => [9,2],
            is_nullable           => 0,
            default_value         => '0.00',
            is_currency           => 1,
            currency_code_column  => 'some_other_column'
        }
    );

=head2 currency_format

=over

=item Arguments: $format

=back

Gets/Sets the format to be used when displaying the currency as a string.

    __PACKAGE__->currency_format('FMT_COMMON');

You can also set this on a per column basis:

    __PACKAGE__->add_columns(
        price => {
            data_type       => 'decimal',
            size            => [9,2],
            is_nullable     => 0,
            default_value   => '0.00',
            is_currency     => 1,
            currency_format => 'FMT_STANDARD'
        }
    );

See L<Locale::Currency::Format|Locale::Currency::Format> for the available
formatting options.

=head2 currency_class

=over

=item Arguments: $class

=back

Gets/sets the currency class that the columns should be inflated into. The
default class is Data::Currency.

    __PACKAGE__->currency_class('MyCurrencySubclass');

You can also set this on a per column basis:

    __PACKAGE__->add_columns(
        price => {
            data_type      => 'decimal',
            size           => [9,2],
            is_nullable    => 0,
            default_value  => '0.00',
            is_currency    => 1,
            currency_class => 'SomeOtherCurrencyClass'
        }
    );

=head2 register_column

Chains with the "register_column" in DBIx::Class::Row method, and sets up
currency columns appropriately. This would not normally be directly called by
end users.

=head1 SEE ALSO

L<Data::Currency>, L<Locale::Currency>, L<Locale::Currency::Format>,
L<Finance::Currency::Convert::WebserviceX>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

