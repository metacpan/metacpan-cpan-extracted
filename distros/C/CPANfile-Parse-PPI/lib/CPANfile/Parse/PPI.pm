package CPANfile::Parse::PPI;

# ABSTRACT: Parse I<cpanfile>s with PPI

use strict;
use warnings;

use PPI;
use Moo;
use Carp qw(carp croak);

our $VERSION = '0.04';

my $strict;

has modules => (
    is  => 'ro',
    isa => sub {
        die if 'ARRAY' ne ref $_[0];
    }
);


sub BUILDARGS {
    my ($class, $file_or_code) = @_;

    my @modules = _parse( $file_or_code );

    return {
        modules => \@modules,
    };
}

sub import {
    $strict = 1 if grep{ $_ eq '-strict' }@_;
}

sub _parse {
    my ($file_or_code) = @_;

    my $doc = PPI::Document->new( $file_or_code );
    my $requires = $doc->find(
        sub { 
            $_[1]->isa('PPI::Token::Word') and (
                $_[1]->content eq 'requires' ||
                $_[1]->content eq 'recommends'
             )
        }
    );

    return if !$requires;

    my @modules;

    REQUIRED:
    for my $required ( @{ $requires || [] } ) {
        my $value = $required->snext_sibling;

        my $type = $required->content;

        my $can_string = $value->can('string') ? 1 : 0;
        my $prereq     = $can_string ?
            $value->string :
            $value->content;

        next REQUIRED if $prereq eq 'perl';

        if (
            $value->isa('PPI::Token::Symbol') ||
            $prereq =~ m{\A[^A-Za-z]}
        ) {
            carp  'Cannot handle dynamic code' if !$strict;
            croak 'Cannot handle dynamic code' if $strict;

            next REQUIRED;
        }

        my $stage = '';

        my $parent_node = $value;

        PARENT:
        while ( 1 ) {
            $parent_node = $parent_node->parent;
            last PARENT if !$parent_node;
            last PARENT if $parent_node->isa('PPI::Document');

            if ( $parent_node->isa('PPI::Structure::Block') ) {
                $parent_node = $parent_node->parent;

                my ($on) = $parent_node->find_first( sub { $_[1]->isa('PPI::Token::Word') && $_[1]->content eq 'on' } );

                next PARENT if !$on;

                my $word = $on->snext_sibling; 
                $stage = $word->can('string') ? $word->string : $word->content;
                
                last PARENT;
            }
        }

        my $version = '';
        my $sibling = $value->snext_sibling;
        SIBLING:
        while ( 1 ) {
            last SIBLING if !$sibling;

            do { $sibling = $sibling->snext_sibling; next SIBLING } if !$sibling->isa('PPI::Token::Operator');

            my $value = $sibling->snext_sibling;
            $version = $value->can('string') ? $value->string : $value->content;

            last SIBLING;
        }

        push @modules, {
            name    => $prereq,
            version => $version,
            type    => $type,
            stage   => $stage,
        };
    }

    return @modules;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPANfile::Parse::PPI - Parse I<cpanfile>s with PPI

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use v5.24;
    use CPANfile::Parse::PPI;
    
    my $path     = '/path/to/cpanfile';
    my $cpanfile = CPANfile::Parse::PPI->new( $path );
    
    # or
    # my $cpanfile = CPANfile::Parse::PPI->new( \$content );
    
    for my $module ( $cpanfile->modules->@* ) {
        my $stage = "";
        $stage    = "on $module->{stage}" if $module->{stage};
        say sprintf "%s is %s", $module->{name}, $module->{type};
    }

=begin pod_coverage

=head2 BUILDARGS

=head2 import

=end pod_coverage

=head1 METHODS

=head2 new

    my $path     = '/path/to/cpanfile';
    my $cpanfile = CPANfile::Parse::PPI->new( $path );
    
    # or
    my $content  = <<'CPANFILE';
    requires "CPANfile::Parse::PPI" => 3.6;';
    on build => sub {
        recommends "Dist::Zilla" => 4.0;
        requires "Test2" => 2.311;
    }
    CPANFILE

    my $cpanfile = CPANfile::Parse::PPI->new( \$content );

=head1 ATTRIBUTES

=head2 modules

Returns a list of modules mentioned in the cpanfile ("perl" is skipped).
Each element is a hashref with these keys:

=over 4

=item * name

=item * version

=item * type

=item * stage

=back

    use CPANfile::Parse::PPI;
    use Data::Printer;

    my $required = 'requires "CPANfile::Parse::PPI" => 3.6;';
    my $cpanfile = CPANfile::Parse::PPI->new( \$required );
    
    my $modules = $cpanfile->modules;
    p $modules;
    
    __DATA__
    [
        [0] {
            name      "CPANfile::Parse::PPI",
            stage     "",
            type      "requires",
            version   3.6
        }
    ]

=head1 LIMITATIONS

As this is a static parser, this module cannot handle dynamic
code like

    for my $module (qw/
        IO::All
        Zydeco::Lite::App
    /) {
        requires $module, '0';
    }

This module warns when the required "module" doesn't look like
a package name.

You can make it die when you pass C<-strict> to the module
when you load it:

    use CPANfile::Parse::PPI -strict;
    use Data::Printer;

    my $required = do { local $/; <DATA> };
    my $cpanfile = CPANfile::Parse::PPI->new( \$required );
    
    my $modules = $cpanfile->modules;
    
    __DATA__
    for my $module (qw/
        IO::All
        Zydeco::Lite::App
    /) {
        requires $module, '0';
    }

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
