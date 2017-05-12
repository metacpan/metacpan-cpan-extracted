package CPANPLUS::Internals::Source::MetaCPAN::Tie;
{
  $CPANPLUS::Internals::Source::MetaCPAN::Tie::VERSION = '0.08';
}

#ABSTRACT: A tie for the MetaCPAN source engine

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

use CPANPLUS::Internals::Source::MetaCPAN::HTTP;
use JSON::PP ();

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

    ### did we look this one up before?
    if( my $obj = $self->{store}->{$key} ) {
        return $obj;
    }

    $key = uc( $key ) if $table eq 'author';

    my $url = $self->{idx} . $table . '/' . $key;

    my $http = CPANPLUS::Internals::Source::MetaCPAN::HTTP->new();

    my $data = {};
    my $href;

    {
      my $str;
      $http->reset;
      my $status = $http->request( $url ) or return;
      return unless $status eq '200';
      return unless $str = $http->body;
      eval { $href = JSON::PP::decode_json( $str ); };
      return unless $href and keys %$href;
    }

    ### expand author if needed
    ### XXX no longer generic :(
    if( $table eq 'module' ) {
        return if $href->{maturity} and $href->{maturity} eq 'developer';
        return unless $href->{indexed};
        $href->{author} = delete $href->{author};
        $href->{module} = $key;
        $href->{version} = delete $href->{version};
        {
          $http->reset;
          my $durl = $self->{idx} . 'release' . '/' . $href->{distribution};
          my $str;
          my $status = $http->request( $durl );
          return unless $status eq '200';
          return unless $str = $http->body;
          my $dref;
          eval { $dref = JSON::PP::decode_json( $str ); };
          return unless $dref and keys %$dref;
          ( $href->{dist_file} = $dref->{download_url} ) =~ s!^.+?authors/id/!!;
        }
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
        $href->{author} = $cb->author_tree( $href->{author} ) or return;
        $data->{$_} = delete $href->{$_}
           for qw(author comment description dslip mtime package module version path);
    }
    else {
        $data->{author} = delete $href->{name};
        $data->{cpanid} = delete $href->{pauseid};
    }

    my $class = {
        module  => 'CPANPLUS::Module',
        author  => 'CPANPLUS::Module::Author',
    }->{ $table };

    my $obj = $self->{store}->{$key} = $class->new( %$data, _id => $cb->_id );

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

    my $http = CPANPLUS::Internals::Source::MetaCPAN::HTTP->new();

    my $status = $http->request( $url ) or return;
    return unless $status eq '200';
    return unless $str = $http->body;

    my $res;
    eval { $res = JSON::PP::decode_json( $str ); };
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

CPANPLUS::Internals::Source::MetaCPAN::Tie - A tie for the MetaCPAN source engine

=head1 VERSION

version 0.08

=head1 DESCRIPTION

CPANPLUS::Internals::Source::MetaCPAN::Tie is a tie for L<CPANPLUS::Internals::Source::MetaCPAN>.

It has no user serviceable parts.

=head1 SEE ALSO

L<CPANPLUS>

L<CPANPLUS::Internals::Source>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Williams and Jos Boumans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
