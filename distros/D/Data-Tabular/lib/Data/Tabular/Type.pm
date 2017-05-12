package Data::Tabular::Type;
use strict;
use warnings;

use overload '""' => \&_render, fallback => 'TRUE';

sub html_text
{
    my $self = shift;
    $self->{data};
}

sub new
{
    my $class = shift;

    bless {
	@_
    }, $class;
}

sub string
{
    my $self = shift;

    $self->{data};
}

sub attributes
{
    {};
}

sub _render
{
    my $self = shift;

    $self->{data};
}

package Data::Tabular::Type::Number;
use base 'Data::Tabular::Type';

package Data::Tabular::Type::Dollar;
use base 'Data::Tabular::Type';

package Data::Tabular::Type::Text;
use base 'Data::Tabular::Type';

package Data::Tabular::Type::Date;
use base 'Data::Tabular::Type';

1;
