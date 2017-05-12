package App::perl2js::Converter::Node::Leaf;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

use App::perl2js::Node::Leaf;

sub to_js_ast {
    my ($self, $context) = @_;
    my $token = $self->token;
    my $name = $token->name;
    my $data = $token->data;

    my $current_class = '';
    if ($context->current_class) {
        $current_class = $context->current_class->token->data;
    }

    if ($name eq 'Int') {
        $token->{data} = $data;
    } elsif ($name eq 'Default') {
        if ($data eq 'undef') {
            $token->{data} = 'undefined';
        } else {
            $token->{data} = $self->cprint(ref($self) . ", " . $name . ": " . $data);
        }
    } elsif ($name eq 'ArgumentArray') {
        $token->{data} = "arguments";
    } elsif ($name eq 'LocalVar') {
        $token->{data} = "var " . $data;
    } elsif ($name eq 'LocalArrayVar') {
        $token->{data} = "var " . substr($data, 1) . "_a";
    } elsif ($name eq 'LocalHashVar') {
        $token->{data} = "var " . substr($data, 1) . "_h";
    } elsif ($name eq 'GlobalVar') {
        $token->{data} = $data;
    } elsif ($name eq 'GlobalArrayVar') {
        $token->{data} = substr($data, 1) . "_a";
    } elsif ($name eq 'GlobalHashVar') {
        $token->{data} = substr($data, 1) . "_h";
    } elsif ($name eq 'Var') {
        my $trimmed = substr($data, 1);
        if ($trimmed eq 'ENV') {
            $token->{data} = 'process.env';
        } else {
            $token->{data} = $data;
        }
    } elsif ($name eq 'ArrayVar') {
        $token->{data} = substr($data, 1) . "_a";
    } elsif ($name eq 'HashVar') {
        $token->{data} = substr($data, 1) . "_h";
    } elsif ($name eq 'Key') {
        $token->{data} = '"' . $data . '"';
    } elsif ($name eq 'Namespace') {
        $data =~ s/.+:://;
        $token->{data} = $data;
    } elsif ($name eq 'RegExp') {
        my $data = $self->data;
        $token->{data} = $data;
    } elsif ($name eq 'ShortScalarDereference') {
        # my $trimmed = substr($data, 1);
        # $token->{data} = $trimmed;
        $token->{data} = $data;
    } elsif ($name eq 'ShortArrayDereference') {
        my $trimmed = substr($data, 2) . "_a";
        $token->{data} = "..." . $trimmed;
    # } elsif ($name eq 'ArrayDereference') {
    #     use Data::Dumper;
    #     delete $self->{parent};
    #     warn Dumper $self;
    #     my $trimmed = "\033[32m" . substr($data, 2) . "\033[0m";
    #     $token->{data} = "..." . $trimmed;
    } elsif ($name eq 'ShortHashDereference') {
        my $trimmed = substr($data, 2) . "_h";
        if ($trimmed eq 'ENV') {
            $trimmed = 'process.env';
        }
        $token->{data} = $trimmed;
    } elsif ($name eq 'SpecificKeyword') {
        if ($data eq '__PACKAGE__') {
            $token->{data} = $current_class;
        } else {
            $token->{data} = $self->cprint(ref($self) . ", " . $name . ": " . $data);
        }
    } elsif ($name eq 'SpecificValue') {
        if ($data eq '$_') {
            $token->{data} = $data;
        } else {
            $token->{data} = $self->cprint(ref($self) . ", " . $name . ": " . $data);
        }
    } elsif ($name eq 'String') {
        $token->{data} = '"' . $data . '"';
    } elsif ($name eq 'RawString') {
        $token->{data} = "'" . $data . "'";
    } else {
        $token->{data} = $self->cprint(ref($self) . ", " . $name . ": " . $data);
    }

    return App::perl2js::Node::Leaf->new(
        token => $self->token,
    );
}

1;
