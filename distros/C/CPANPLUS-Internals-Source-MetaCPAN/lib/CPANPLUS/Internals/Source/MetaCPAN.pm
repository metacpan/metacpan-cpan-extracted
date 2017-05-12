package CPANPLUS::Internals::Source::MetaCPAN;
{
  $CPANPLUS::Internals::Source::MetaCPAN::VERSION = '0.08';
}

#ABSTRACT: MetaCPAN source implementation

use strict;
use warnings;

use base 'CPANPLUS::Internals::Source';

use CPANPLUS::Error;
use CPANPLUS::Internals::Constants;
use CPANPLUS::Internals::Source::MetaCPAN::Tie;

use Params::Check               qw[allow check];
use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';
use Module::Load::Conditional   qw[check_install];

use constant METACPAN => 'http://api.metacpan.org/';

{
    my $metacpan = METACPAN;

    sub _init_trees {
        my $self = shift;
        my $conf = $self->configure_object;
        my %hash = @_;

        my($path,$uptodate,$verbose,$use_stored);
        my $tmpl = {
            path        => { default => $conf->get_conf('base'), store => \$path },
            verbose     => { default => $conf->get_conf('verbose'), store => \$verbose },
            uptodate    => { required => 1, store => \$uptodate },
            use_stored  => { default  => 1, store => \$use_stored },
        };

        check( $tmpl, \%hash ) or return;

        ### set up the author tree
        {   my %at;
            tie %at, 'CPANPLUS::Internals::Source::MetaCPAN::Tie',
                idx => $metacpan, table => 'author',
                key => 'cpanid',            cb => $self;

            $self->_atree( \%at  );
        }

        ### set up the module tree
        {   my %mt;
            tie %mt, 'CPANPLUS::Internals::Source::MetaCPAN::Tie',
                idx => $metacpan, table => 'module',
                key => 'module',            cb => $self;

            $self->_mtree( \%mt  );
        }

        return 1;

    }

    sub _standard_trees_completed   { return 1 }
    sub _custom_trees_completed     { return }
    ### finish transaction
    sub _finalize_trees             { return 1 }

    ### no saving state in metacpan
    sub _save_state                 { return }
    sub __check_uptodate            { return 1 }
    sub _check_trees                { return 1 }

    sub _add_author_object {
      my $self = shift;
      my %hash = @_;
      return 1;

      my $class;
      my $tmpl = {
        class   => { default => 'CPANPLUS::Module::Author', store => \$class },
        map { $_ => { required => 1 } }
            qw[ author cpanid email ]
      };

      my $href = do {
        local $Params::Check::NO_DUPLICATES = 1;
        check( $tmpl, \%hash ) or return;
      };

      my $obj = $class->new( %$href, _id => $self->_id );

      $self->author_tree->{ $href->{'cpanid'} } = $obj or return;

      return $obj;
    }

  sub _add_module_object {
    my $self = shift;
    my %hash = @_;

    my $class;
    my $tmpl = {
        class   => { default => 'CPANPLUS::Module', store => \$class },
        map { $_ => { required => 1 } }
            qw[ module version path comment author package description dslip mtime ]
    };

    my $href = do {
        local $Params::Check::NO_DUPLICATES = 1;
        check( $tmpl, \%hash ) or return;
    };

    return unless check_install( module => $href->{module} );

    my $obj = $class->new( %$href, _id => $self->_id );

    ### Every module get's stored as a module object ###
    $self->module_tree->{ $href->{module} } = $obj or return;

    return $obj;
  }

}

{   my %map = (
        _source_search_module_tree
            => [ module => module => 'CPANPLUS::Module' ],
        _source_search_author_tree
            => [ author => cpanid => 'CPANPLUS::Module::Author' ],
    );

    while( my($sub, $aref) = each %map ) {
        no strict 'refs';

        my($table, $key, $class) = @$aref;
        *$sub = sub {
            my $self = shift;
            my %hash = @_;

            my($list,$type);
            my $tmpl = {
                allow   => { required   => 1, default   => [ ], strict_type => 1,
                             store      => \$list },
                type    => { required   => 1, allow => [$class->accessors()],
                             store      => \$type },
            };

            check( $tmpl, \%hash ) or return;

            my @rv;
            ### we aliased 'module' to 'name', so change that here too
            #$type = 'module' if $type eq 'name';

            #my $res = $dbh->query( "SELECT * from $table" );

            #my $meth = $table .'_tree';
            #my @rv = map  { $self->$meth( $_->{$key} ) }
            #         grep { allow( $_->{$type} => $list ) } $res->hashes;

            return @rv;
        }
    }
}

1;

__END__

=pod

=head1 NAME

CPANPLUS::Internals::Source::MetaCPAN - MetaCPAN source implementation

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  # In the CPANPLUS shell

  CPAN Terminal> s conf no_update 1
  CPAN Terminal> s conf source_engine CPANPLUS::Internals::Source::MetaCPAN
  CPAN Terminal> s save

=head1 DESCRIPTION

CPANPLUS::Internals::Source::MetaCPAN is a L<http://metacpan.org/> source implementation.

It is highly experimental.

Usually L<CPANPLUS> retrieves the CPAN index files, extracts them and builds
an in-memory index of every module listed on CPAN. As you can imagine, this is
quite memory intensive.

This source implementation does things slightly different.

Instead of building an in-memory index, it queries the L<http://metacpan.org/>
website for module/distribution/author information as and when it is required
by L<CPANPLUS>.

=head1 CAVEATS

There are some caveats.

As shown in the L</SYNOPSIS> you must set the L<CPANPLUS> configuration variable
C<no_update> to a true value to use this source engine. This prevents L<CPANPLUS> from
attempting to update CPAN indexes.

Attempting to do searches and getting a list of out of date modules in L<CPANPLUS> are
incredibly slow due the million or so web accesses that are incurred.

=head1 SEE ALSO

L<CPANPLUS>

L<CPANPLUS::Internals::Source>

L<http://metacpan.org/>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Williams and Jos Boumans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
