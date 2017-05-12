package CPANPLUS::Internals::Source::CPANIDX::Tie;
BEGIN {
  $CPANPLUS::Internals::Source::CPANIDX::Tie::VERSION = '0.04';
}

#ABSTRACT: A tie for the CPANIDX source engine

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

use CPANPLUS::Internals::Source::CPANIDX::HTTP;
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
    
    my $url = $self->{idx} . "yaml/$lkup/" . $key;
    my $str;

    my $http = CPANPLUS::Internals::Source::CPANIDX::HTTP->new();

    my $status = $http->request( $url ) or return;
    return unless $status eq '200';
    return unless $str = $http->body;

    my $res;
    eval { $res = Parse::CPAN::Meta::Load( $str ); };
    return unless $res;

    my $href = $res->[0];
    
    ### no results?
    return unless keys %$href;
    
    ### expand author if needed
    ### XXX no longer generic :(
    if( $table eq 'module' ) {
        $href->{author} = delete $href->{cpan_id};
        $href->{module} = delete $href->{mod_name};
        $href->{version} = delete $href->{mod_vers};
        my ($author, $package) = $href->{dist_file} =~
                m|  (?:[A-Z\d-]/)?
                    (?:[A-Z\d-]{2}/)?
                    ([A-Z\d-]+) (?:/[\S]+)?/
                    ([^/]+)$
                |xsg;

        ### remove file name from the path
        $href->{dist_file} =~ s|/[^/]+$||;
        $href->{path} = join '/', 'authors/id', delete $href->{dist_file};
        $href->{package} = $package;
        $href->{comment} = $href->{description} = $href->{dslip} = $href->{mtime} = '';
        delete $href->{$_} for qw(dist_vers dist_name);
        $href->{author} = $cb->author_tree( $href->{author} ) or return;
    }
    else {
        $href->{author} = delete $href->{fullname};
        $href->{cpanid} = delete $href->{cpan_id};
    }

    my $class = {
        module  => 'CPANPLUS::Module',
        author  => 'CPANPLUS::Module::Author',
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

    my $http = CPANPLUS::Internals::Source::CPANIDX::HTTP->new();

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

qq[Tie your mother down];


__END__
=pod

=head1 NAME

CPANPLUS::Internals::Source::CPANIDX::Tie - A tie for the CPANIDX source engine

=head1 VERSION

version 0.04

=head1 DESCRIPTION

CPANPLUS::Internals::Source::CPANIDX::Tie is a tie for L<CPANPLUS::Internals::Source::CPANIDX>.

It has no user serviceable parts.

=head1 SEE ALSO

L<CPANPLUS>

L<CPANPLUS::Internals::Source>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams and Jos Boumans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

