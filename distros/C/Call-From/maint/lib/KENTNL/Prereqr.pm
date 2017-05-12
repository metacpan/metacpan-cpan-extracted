use 5.006;    # our
use strict;
use warnings;

package KENTNL::Prereqr;
use Carp qw( carp );

# ABSTRACT: Scrape prereqs and provides data from modules

sub new {
    bless { ref $_[1] ? %{ $_[1] } : @_[ 1 .. $#_ ] }, $_[0];
}

sub rules {
    return ( $_[0]->{rules} ||= [] );
}

sub scanner {
    return (
        $_[0]->{scanner} ||= do {
            require Perl::PrereqScanner;
            Perl::PrereqScanner->new;
          }
    );
}

sub _add_requirements {
    my ( $self, $target, $stage, $requirements ) = @_;
    $target->requirements_for( @{$stage} )->add_requirements($requirements);
}

sub _is_provide_blacklisted {
    my ( $self, $path, $name ) = @_;
    if ( $name =~ /\A(main|DB)\z/ ) {
      #   carp( "blacklisted: Bad Namespace $name in $path");
        return 1;
    }
    if ( $name =~ qr/\A_/ ) {
        carp( "Unindexable: Leading underscore in $name in $path" );
        return 1;
    }
    if ( $name =~ qr/::_/ ) {
        carp( "Unindexable: Private Package ( ::_ ) in $name in $path");
        return 1;
    }
    return;
}

sub _add_provides {
    my ( $self, $path, $target, $stage, $provides ) = @_;
    for my $provide ( keys %{$provides} ) {
        next if $self->_is_provide_blacklisted($path, $provide);
        $target->{$stage}->{$provide} = $provides->{$provide};
    }
}

sub _get_provide {
    my ( $self, $path ) = @_;
    require Module::Metadata;
    my $mm = Module::Metadata->new_from_file( $path, collect_pod => 0 );
    my $provides = {};
    for my $namespace ( $mm->packages_inside() ) {
        my $v = $mm->version($namespace);
        $provides->{$namespace} = {
            file    => $path,
            version => $v,
        };
    }
    return $provides;
}

sub _run_rule {
    my ( $self, $rule, $requires, $provides ) = @_;
    for my $in_dir ( @{ $rule->{start_in} } ) {
        my $iter = $rule->{rule}->iter($in_dir);
        while ( my $entry = $iter->() ) {
            if ( $rule->{deps_to} ) {
                $self->_add_requirements( $requires, $rule->{deps_to},
                    $self->scanner->scan_file($entry) );
            }
            if ( $rule->{provides_to} ) {
                my $provided = $self->_get_provide($entry);
                for my $to ( @{ $rule->{provides_to} } ) {
                    $self->_add_provides( $entry, $provides, $to, $provided );
                }
            }
        }
    }
}

sub collect {
    return @{
        $_[0]->{collected} ||= do {
            require CPAN::Meta::Prereqs;
            my $reqs     = CPAN::Meta::Prereqs->new();
            my $provides = {};
            for my $rule ( @{ $_[0]->rules } ) {
                $_[0]->_run_rule( $rule, $reqs, $provides );
            }
            [ $reqs, $provides ];
          }
    };
}

sub prereqs {
  return ( $_[0]->{prereqs} ||= do {
      my ( $reqs, $provides ) = $_[0]->collect;
      
      $reqs = $reqs->clone;
      for my $phase ( keys %{ $provides } ) {
        for my $rel ( qw( requires recommends suggests )  ) {
          my $preqs = $reqs->requirements_for( $phase, $rel );
          for my $module ( keys %{$provides->{$phase}} ) {
            if ( $preqs->accepts_module( $module,$provides->{$phase}->{$module}->{version} ) ) {
              $preqs->clear_requirement( $module );
            }
          }
        }
      }
      return $reqs;
  });
}

1;

