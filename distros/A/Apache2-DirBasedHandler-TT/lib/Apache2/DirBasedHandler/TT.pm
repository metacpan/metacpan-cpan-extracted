package Apache2::DirBasedHandler::TT;

use strict;
use warnings;

use base qw(Apache2::DirBasedHandler);

use Template;
our $tt;
our $VERSION = 0.03;

sub init {
    my ($self,$r) = @_;
    my $hash = $self->SUPER::init($r);
    my ($tt,$vars) = $self->get_tt($r);
    $hash->{'tt'} = $tt;
    $hash->{'vars'} = $vars;
    return $hash;
}

sub get_tt {
    my $self = shift;
    my $r = shift;

    $tt ||= Template->new({
        'INCLUDE_PATH' => [$r->document_root],
    });

    my $vars = {};
    if ($r) {
        $vars->{'r'} = $r;
    };

    return ($tt,$vars);
}

sub process_template {
    my ($self,$r,$tt,$vars,$template_name,$content_type) = @_;
    my $page_out;
    if (!$tt->process($template_name, $vars, \$page_out)) {
        $r->log_error($template_name . q[ ] . $tt->error);
        return Apache2::Const::SERVER_ERROR;
    }

    return (Apache2::Const::OK,$page_out,$content_type);
}

1;

__END__

=head1 NAME

Apache2::DirBasedHandler::TT - TT hooked into DirBasedHandler

=head1 VERSION

This documentation refers to <Apache2::DirBasedHandler::TT> version 0.03

=head1 SYNOPSIS

  package My::Thingy;

  use strict;

  use Apache2::DirBasedHandler::TT
  our @ISA = qw(Apache2::DirBasedHandler::TT);

  use Apache2::Const -compile => qw(:common);

  sub root_index {
      my $self = shift;
      my ($r,$uri_args,$args) = @_;

      if (@$uri_args) {
          return Apache2::Const::NOT_FOUND;
      }
      $$args{'vars'}{'blurb'} = qq[this is the index];

      return $self->process_template(
          $r,
          $$args{'tt'},
          $$args{'vars'},
          qq[blurb.tmpl],
          qq[text/plain; charset=utf-8],
      );
  }
  
  sub super_page {
      my $self = shift;
      my ($r,$uri_args,$args) = @_;
      $$args{'vars'}{'blurb'} = qq[this is \$location/super and all it's contents];

      return $self->process_template(
          $r,
          $$args{'tt'},
          $$args{'vars'},
          qq[blurb.tmpl],
          qq[text/plain; charset=utf-8],
      );
  }

  sub super_dooper_page {
      my $self = shift;
      my ($r,$uri_args,$args) = @_;
      $$args{'vars'}{'blurb'} = qq[this is \$location/super/dooper and all it's contents];

      return $self->process_template(
          $r,
          $$args{'tt'},
          $$args{'vars'},
          qq[blurb.tmpl],
          qq[text/plain; charset=utf-8],
      );
  }

  1;

=head1 DESCRIPTION

Apache2::DirBasedHandler::TT, is an subclass of Apache2::DirBasedHandler with modified
to allow easy use of Template Toolkit templates for content generation.

=head2 init

C<init> calls get_tt to get the template object, and stuffs it into the hash it gets back
from the super class.

=head2 get_tt

C<get_tt> returns a Template Toolkit object, and a hash reference of variables which
will be passed into the TT process call.  You should really override this function with 
to create the Template object appropriate to your environment.

=head2 process_template

C<process_template> is a helper function to generate a page based using the
template object, variables, and template passed in.  It sets the content_type
of the response to the value of the fifth argument.

=head1 DEPENDENCIES

This module requires modperl 2 (http://perl.apache.org), and
libapreq (http://httpd.apache.org/apreq/) which must be installed seperately.
It also depends on Apache2::DirBasedHandler

=head1 INCOMPATIBILITIES

There are no known incompatibilities for this module.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report any problems through

http://rt.cpan.org/Public/Dist/Display.html?Name=Apache2-DirBasedHandler-TT

=head1 AUTHOR

Adam Prime (adam.prime@utoronto.ca)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 by Adam Prime (adam.prime@utoronto.ca).  All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.  See L<perlartistic>.

This module is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.
