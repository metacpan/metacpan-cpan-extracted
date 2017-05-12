package Module::AnyEvent::Helper::PPI::Transform::Net::Amazon::S3::Client::Bucket;

# ABSTRACT: Additional transformer for Module::AnyEvent::Helper
our $VERSION = 'v0.04.0.80'; # VERSION

use strict;
use warnings;

use parent qw(Module::AnyEvent::Helper::PPI::Transform::Net::Amazon::S3);

use Module::AnyEvent::Helper::PPI::Transform qw(is_function_declaration copy_children emit_cv replace_as_async);

my $list_def = PPI::Document->new(\'sub list { return shift->list_async(@_); }');
my $return_undef = PPI::Document->new(\'if($end) { $___cv___->send; return $___cv___; }');
my $var_def = PPI::Document->new(\'my $marker = $conf->{marker};my $max_keys = $conf->{max_keys} || 1000;');
my $req_def_ = <<'EOF';
my $http_request = AnyEvent::Net::Amazon::S3::Request::ListBucket->new(
                s3     => $self->client->s3,
                bucket => $self->name,
                marker => $marker,
                prefix => $prefix,
                max_keys => $max_keys,
            )->http_request;
EOF
my $req_def = PPI::Document->new(do { chop($req_def_); \$req_def_ });

sub document
{
    my ($self, $doc) = @_;
    $self->SUPER::document($doc);

# Find target
    my $list_decl = $doc->find_first(sub {
        $_[1]->isa('PPI::Token::Word') && is_function_declaration($_[1]) && $_[1]->content eq 'list';
    });
    my $sub_block = $list_decl->snext_sibling->find_first(sub {
        $_[1]->isa('PPI::Token::Word') && $_[1]->content eq 'sub';
    })->snext_sibling;

# sub block transformation
    my $target = $sub_block->find_first(sub {
        $_[1]->isa('PPI::Token::Word') && $_[1]->content eq '_send_request_xpc';
    });
    replace_as_async($target, '_send_request_xpc_async', 0);
    emit_cv($sub_block);
    $list_decl->set_content('list_async');
    my $target2 = $sub_block->find_first(sub {
        $_[1]->isa('PPI::Token::Symbol') && $_[1]->content eq '$end';
    });
    copy_children(undef, $target2->statement->snext_sibling, $return_undef);
    $target2->statement->delete;

# Additional options
    my $var = $doc->find_first(sub {
        $_[1]->isa('PPI::Statement::Variable') &&
            $_[1]->schild(0)->isa('PPI::Token::Word') && $_[1]->schild(0)->content eq 'my' &&
            $_[1]->schild(1)->isa('PPI::Token::Symbol') && $_[1]->schild(1)->content eq '$marker';
    });
    copy_children(undef, $var->snext_sibling, $var_def);
    $var->delete;
    my $req = $sub_block->find_first(sub {
        $_[1]->isa('PPI::Statement::Variable') &&
            $_[1]->schild(0)->isa('PPI::Token::Word') && $_[1]->schild(0)->content eq 'my' &&
            $_[1]->schild(1)->isa('PPI::Token::Symbol') && $_[1]->schild(1)->content eq '$http_request';
    });
    copy_children(undef, $req->snext_sibling, $req_def);
    $req->delete;


# Add list() definition
    copy_children($list_decl->statement, undef, $list_def);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::AnyEvent::Helper::PPI::Transform::Net::Amazon::S3::Client::Bucket - Additional transformer for Module::AnyEvent::Helper

=head1 VERSION

version v0.04.0.80

=head1 SYNOPSIS

  use Module::AnyEvent::Helper::Filter -transformer => 'Net::Amazon::S3::Client::Bucket', -target => 'Net::Amazon::S3::Client::Bucket';

=head1 DESCRIPTION

This class is not intended to use directly.

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
