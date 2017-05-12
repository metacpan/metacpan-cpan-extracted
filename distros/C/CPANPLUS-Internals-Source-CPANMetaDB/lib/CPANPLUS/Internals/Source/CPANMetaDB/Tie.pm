package CPANPLUS::Internals::Source::CPANMetaDB::Tie;
{
  $CPANPLUS::Internals::Source::CPANMetaDB::Tie::VERSION = '0.06';
}

#ABSTRACT: A tie for the CPAN Meta DB source engine

use strict;
use warnings;

use CPANPLUS::Error;
use CPANPLUS::Module;
use CPANPLUS::Module::Fake;
use CPANPLUS::Module::Author::Fake;
use CPANPLUS::Internals::Constants;


use Params::Check               qw[check];
use Module::Load::Conditional   qw[can_load];
use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';

use CPANPLUS::Internals::Source::CPANMetaDB::HTTP;
use Parse::CPAN::Meta;

require Tie::Hash;
use vars qw[@ISA];
push @ISA, 'Tie::StdHash';

sub TIEHASH {
    my $class = shift;
    my %hash  = @_;
    
    my $tmpl = {
        idx     => { required => 1 },
        table   => { required => 1 },
        key     => { required => 1 },
        cb      => { required => 1 },
        offset  => { default  => 0 },
    };
    
    my $args = check( $tmpl, \%hash ) or return;
    my $obj  = bless { %$args, store => {} } , $class;

    return $obj;
}    

sub FETCH {
    my $self    = shift;
    my $key     = shift or return;
    my $idx     = $self->{idx};
    my $cb      = $self->{cb};
    my $table   = $self->{table};
    
    my $lkup = $table eq 'module' ? 'mod' : 'auth';
    
    ### did we look this one up before?
    if( my $obj = $self->{store}->{$key} ) {
        return $obj;
    }
    
    my $href;

    if( $table eq 'module' ) {
        my $url = $self->{idx} . "/v1.0/package/" . $key;
        my $str;

        my $http = CPANPLUS::Internals::Source::CPANMetaDB::HTTP->new();

        my $status = $http->request( $url ) or return;
        return unless $status eq '200';
        return unless $str = $http->body;

        eval { $href = Parse::CPAN::Meta::Load( $str ); };
        return unless $href and keys %$href;

        $href->{module} = $key;
        my ($author, $package) = $href->{distfile} =~
                m|  (?:[A-Z\d-]/)?
                    (?:[A-Z\d-]{2}/)?
                    ([A-Z\d-]+) (?:/[\S]+)?/
                    ([^/]+)$
                |xsg;
        $href->{author} = $author;
        ### remove file name from the path
        $href->{distfile} =~ s|/[^/]+$||;
        $href->{path} = join '/', 'authors/id', delete $href->{distfile};
        $href->{package} = $package;
        $href->{comment} = $href->{description} = $href->{dslip} = $href->{mtime} = '';
        $href->{author} = $cb->author_tree( $href->{author} ) or return;
    }
    else {
        $href->{cpanid} = $key;
    }

    my $class = {
        module  => 'CPANPLUS::Module',
        author  => 'CPANPLUS::Module::Author::Fake',
    }->{ $table };

    my $obj = $self->{store}->{$key} = $class->new( %$href, _id => $cb->_id );   
    
    return $obj;
}

sub STORE { 
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    
    $self->{store}->{$key} = $val;
}

sub FIRSTKEY {
    my $self = shift;
    my $idx  = $self->{'idx'};
    my $table   = $self->{table};

    my $lkup = $table eq 'module' ? 'mod' : 'auth';
    my $url = $idx . "yaml/${lkup}keys";

    my $str;

    my $http = CPANPLUS::Internals::Source::CPANMetaDB::HTTP->new();

    my $status = $http->request( $url ) or return;
    return unless $status eq '200';
    return unless $str = $http->body;

    my $res;
    eval { $res = Parse::CPAN::Meta::Load( $str ); };
    return unless $res;

    my $ref = $table eq 'module' ? 'mod_name' : 'cpan_id';
    @{ $self->{keys} } = 
      map { $_->{$ref} } @$res;

    $self->{offset} = 0;

    return $self->{keys}->[0];
}

sub NEXTKEY {
    my $self = shift;
    my $idx  = $self->{'idx'};
    my $table   = $self->{table};

    my $key = $self->{keys}->[ $self->{offset} ];
    
    $self->{offset} +=1;

    if ( wantarray ) {
      ### use each() semantics
      my $val = $self->FETCH( $key );
      return ( $key, $val );
    }
    return $key;
}

sub EXISTS   { !!$_[0]->FETCH( $_[1] ) }

### intentionally left blank
sub DELETE   {  }
sub CLEAR    {  }

qq[Tie your mother down]


__END__
=pod

=head1 NAME

CPANPLUS::Internals::Source::CPANMetaDB::Tie - A tie for the CPAN Meta DB source engine

=head1 VERSION

version 0.06

=head1 DESCRIPTION

CPANPLUS::Internals::Source::CPANMetaDB::Tie is a tie for L<CPANPLUS::Internals::Source::CPANMetaDB>.

It has no user serviceable parts.

=head1 SEE ALSO

L<CPANPLUS>

L<CPANPLUS::Internals::Source>

L<http://cpanmetadb.appspot.com/>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Jos Boumans <kane@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams, Jos Boumans, Roy Hooper and Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

