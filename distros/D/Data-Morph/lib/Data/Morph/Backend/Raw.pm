package Data::Morph::Backend::Raw;
$Data::Morph::Backend::Raw::VERSION = '1.140400';
#ABSTRACT: Provides a backend that produces simple HashRefs

use Moose;
use MooseX::Params::Validate;
use MooseX::Types::Moose(':all');
use Data::DPath(qw|dpath dpathr|);
use Devel::PartialDump('dump');
use namespace::autoclean;


has new_instance =>
(
    is => 'ro',
    isa => CodeRef,
    default => sub { sub { +{} } },
);


sub epilogue { }

with 'Data::Morph::Role::Backend' =>
{
    input_type => HashRef,
    get_val => sub
    {
        my ($obj, $key) = @_;
        my @keys = split('\|', $key);
        my @refs;

        if(scalar(@keys) > 1)
        {
            foreach my $alt (@keys)
            {
                @refs = dpath($alt)->match($obj);
                last if scalar(@refs);
            }
        }
        else
        {
            @refs = dpath($key)->match($obj);
        }

        die "No matching points for key '$key' in: \n". dump($obj)
            unless scalar(@refs);

        die "Too many maching points for '$key' in: \n". dump($obj)
            if scalar(@refs) > 1;

        return $refs[0];
    },
    set_val => sub
    {
        my ($obj, $key, $val) = @_;

        if(index($key, '|') > -1)
        {
            die "Alternations are not supported for write directives: '$key'"
        }

        my @refs = dpathr($key)->match($obj);

        die "Too many maching points for '$key' in: \n". dump($obj)
            if scalar(@refs) > 1;

        unless(scalar(@refs))
        {
            my @paths = split('/', $key);
            my $place = $obj;

            for(0..$#paths)
            {
                next if $paths[$_] eq '';
                my $path = $paths[$_];
                
                # handling arrays in path
                if ($path =~ /\*\[\d+\]/)
                {
                    my ($index) = $path =~ /\*\[(\d+)\]/;
                    
                    if($_ == $#paths)
                    {
                        $place->[$index] = $val;
                    }
                    else
                    {
                        if (!defined($place->[$index]))
                        {
                            $place->[$index] = ($paths[$_+1] =~ m/\*\[\d+\]/ ? [] : {});
                        }
                        
                        $place = ref($place->[$index]) eq 'HASH' ? \%{$place->[$index]} : \@{$place->[$index]};
                    }

                }
                else
                {
                    if($_ == $#paths)
                    {
                        $place->{$path} = $val;
                    }
                    else
                    {
                        if (!exists($place->{$path}))
                        {
                            $place->{$path} = ($paths[$_+1] =~ m/\*\[\d+\]/ ? [] : {});
                        }
                        
                        $place = ref($place->{$path}) eq 'HASH' ? \%{$place->{$path}} : \@{$place->{$path}};
                    }
                }
            }
        }
        else
        {
            ${$refs[0]} = $val;
        }
    },
};

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=head1 NAME

Data::Morph::Backend::Raw - Provides a backend that produces simple HashRefs

=head1 VERSION

version 1.140400

=head1 DESCRIPTION

Data::Morph::Backend::Raw is a backend for L<Data::Morph> that deals with raw Perl hashes. Map directives are more complicated than the other shipped backends like L<Data::Morph::Backend::Object>. The keys should be paths as defined by L<Data::DPath>. Read and write operations can have rather complex dpaths defined for them to set or return values. There are two special cases: one for read directives and another for write directives. Read directives can accept alternations using pipe (eg. '|') as a delimiter. The rules for alternations are simple: first match wins. If an alternation is attempted in a write directive an exception will be thrown. The other special case is when the dpath for a write operation points to a non-existant piece: the substrate is created for you and the value deposited. One caveat is that the path must be dumb simple without fancy filtering. Hash and array access (using the syntax '*[1]') into the path is supported. Please see L<Data::Morph/SYNOPSIS> for an exmaple of a map using the Raw backend.

=head1 PUBLIC_ATTRIBUTES

=head2 new_instance

    is: ro, isa: CodeRef

This attribute overrides L<Data::Morph::Role::Backend/new_instance> and
provides a default coderef that simply returns empty hash references

=head1 PUBLIC_METHODS

=head2 epilogue

Implements L<Data::Morph::Role::Backend/epilogue> as a no-op

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
