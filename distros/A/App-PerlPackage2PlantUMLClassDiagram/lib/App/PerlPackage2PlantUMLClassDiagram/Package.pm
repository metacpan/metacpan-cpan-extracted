package App::PerlPackage2PlantUMLClassDiagram::Package;
use 5.014;
use strict;
use warnings;

use PPI::Document;
use Text::MicroTemplate::DataSection 'render_mt';

sub new {
    my ($class, $source) = @_;

    unless (-f $source) {
        die "file not exist: $source";
    }

    bless {
        source => $source,
    }, $class;
}

sub source {
    my ($self) = @_;

    $self->{source};
}

sub document {
    my ($self) = @_;

    $self->{document} ||= PPI::Document->new($self->source);
}

sub package_name {
    my ($self) = @_;

    my $package = $self->document->find_first('PPI::Statement::Package');
    return unless $package;
    $package->namespace;
}

sub parent_packages {
    my ($self) = @_;

    my $includes = $self->document->find('PPI::Statement::Include') || [];
    return [] unless $includes;

    my $parent_packages = [];

    # see also: App::PRT::Command::RenameClass
    for my $statement (@$includes) {
        next unless defined $statement->pragma;
        next unless $statement->pragma =~ /^parent|base$/; # only 'use parent' and 'use base' are supported

        # schild(2) is 'Foo' of use parent Foo
        my $parent = $statement->schild(2);

        if ($parent->isa('PPI::Token::Quote')) {
            # The 'literal' method is not implemented by ::Quote::Double or ::Quote::Interpolate.
            push @$parent_packages, $parent->can('literal') ? $parent->literal : $parent->string;
        } elsif ($parent->isa('PPI::Token::QuoteLike::Words')) {
            # use parent qw(A B C) pattern
            # literal is array when QuoteLike::Words
            push @$parent_packages, $parent->literal;
        }
    }

    $parent_packages;
}

sub _methods {
    my ($self) = @_;

    $self->document->find('PPI::Statement::Sub') || [];
}

sub _arguments ($) {
    my ($sub) = @_;

    my $variable = $sub->find_first('PPI::Statement::Variable');
    return () unless $variable;

    my $list = $variable->find_first('PPI::Structure::List');
    return () unless $list;

    my $symbols = $list->find('PPI::Token::Symbol') || [];
    return () unless @$symbols;
    my $receiver = shift @$symbols if $symbols->[0]->content eq '$self' || $symbols->[0]->content eq '$class';
    ($receiver, @$symbols);
}

sub _method_signature ($) {
    my ($sub) = @_;

    my (undef, @arguments) = _arguments($sub);

    "@{[ $sub->name ]}(@{[ join ', ', @arguments ]})";
}

sub static_methods {
    my ($self) = @_;
    [ map { _method_signature $_ } grep {
        my ($receiver) = _arguments $_;
        $receiver && $receiver eq '$class';
    } @{$self->_methods} ];
}

sub public_methods {
    my ($self) = @_;

    [ map { _method_signature $_ } grep { index($_->name, '_') != 0 } grep {
        my ($receiver) = _arguments $_;
        !$receiver || $receiver eq '$self';
    } @{$self->_methods} ];
}

sub private_methods {
    my ($self) = @_;

    [ map { _method_signature $_ } grep { index($_->name, '_') == 0 } grep {
        my ($receiver) = _arguments $_;
        !$receiver || $receiver eq '$self';
    } @{$self->_methods} ];
}

sub to_class_syntax {
    my ($self) = @_;

    my $package_name = $self->package_name;

    return '' unless $package_name;

    render_mt('class_syntax', {
        package_name => $self->package_name,
        static_methods => $self->static_methods,
        public_methods => $self->public_methods,
        private_methods => $self->private_methods,
    });
}

sub to_inherit_syntax {
    my ($self) = @_;

    my $parent_packages = $self->parent_packages;

    return '' unless @$parent_packages;

    render_mt('inherit_syntax', {
        package_name => $self->package_name,
        parent_packages => $parent_packages,
    });
}

1;
__DATA__

@@ class_syntax
class <?= $_[0]->{package_name} ?> {
? for my $static_method (@{$_[0]->{static_methods}}) {
  {static} <?= $static_method ?>
? }
? for my $public_method (@{$_[0]->{public_methods}}) {
  + <?= $public_method ?>
? }
? for my $private_method (@{$_[0]->{private_methods}}) {
  - <?= $private_method ?>
? }
}
@@ inherit_syntax
? for my $parent_package (@{$_[0]->{parent_packages}}) {
<?= $parent_package ?> <|-- <?= $_[0]->{package_name} ?>
? }
