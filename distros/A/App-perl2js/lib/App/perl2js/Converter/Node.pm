package App::perl2js::Converter::Node;

use strict;
use warnings;
use parent qw(Compiler::Parser::Node);

use App::perl2js::Converter::Node::ArrayRef;
use App::perl2js::Node::Nop;
use Data::Dumper;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub is_nop {
    my ($self) = @_;
    return $self->isa("App::perl2js::Converter::Node::Nop");
}

sub to_js_ast {
    my ($self) = @_;
    warn "\033[32m not implemented: " . ref ($self) . " \033[0m";
    return App::perl2js::Node::Nop->new;
}

sub search {
    my ($node, $query) = @_;
    my $current = $node;
    while ($current) {
        my $success = 1;
        my $target = +{
            ref => ref($current),
            %{$current->token}
        };
        for my $key (keys %$query) {
            my $value = $query->{$key};
            if ($target->{$key} ne $value) {
                $success = 0;
            }
        }
        if ($success) {
            return $current;
        } else {
            my $body = $current->can('body') && $current->body;
            if ($body) {
                search($body, $query);
            }
            $current = $current->next;
        }
    }
}

sub cprint {
    my ($self, $str) = @_;
    return "/* \033[32m " . $str . " \033[0m */";
}

sub remove_node {
    my ($node) = @_;
    my $parent = $node->parent;
    next unless $parent;
    foreach my $branch (@{$parent->branches}, 'next') {
        my $child = $parent->{$branch};
        next unless ($child && $child == $node);
        $parent->{$branch} = $node->next;
    }
}

sub shift_comma_branch {
    my ($branch) = @_; # Node::Branch / Comma
    if (ref($branch) ne 'App::perl2js::Converter::Node::Branch') {
        return {
            new_root => $branch,
            most_left => undef
        }
    }
    my $most_left;
    my $shift; $shift = sub {
        my ($branch) = @_;
        if (ref($branch->left) eq 'App::perl2js::Converter::Node::Branch') {
            my $new_left = $shift->($branch->left);
            if ($new_left) {
                $branch->{left} = $new_left;
            }
            return;
        } else {
            $most_left = $branch->left;
            return $branch->right;
        }
    };
    # return new root node too.
    return {
        new_root => $shift->($branch) || $branch,
        most_left => $most_left
    };
}

# App::perl2js::Converter::Node::CodeDereference
# App::perl2js::Converter::Node::Handle
# App::perl2js::Converter::Node::HandleRead
# App::perl2js::Converter::Node::Label
# App::perl2js::Converter::Node::RegReplace
# App::perl2js::Converter::Node::RegPrefix
# App::perl2js::Converter::Node::Regexp

1;
