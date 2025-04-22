# Copyrights 2012-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Apache-Solr.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Apache::Solr::Document;{
our $VERSION = '1.10';
}


use warnings;
use strict;

use Log::Report    qw(solr);


sub new(@) { my $c = shift; (bless {}, $c)->init({@_}) }
sub init($)
{   my ($self, $args) = @_;

    $self->{ASD_boost}    = $args->{boost} || 1.0;
    $self->{ASD_fields}   = [];   # ordered
    $self->{ASD_fields_h} = {};   # grouped by name
    $self->addFields($args->{fields});
    $self;
}


sub fromResult($$)
{   my ($class, $data, $rank) = @_;
    my (@f, %fh);
    
    while(my($k, $v) = each %$data)
    {   my @v = map +{name => $k, content => $_}
             , ref $v eq 'ARRAY' ? @$v : $v;
        push @f, @v;
        $fh{$k} = \@v;
    }

    my $self = $class->new;
    $self->{ASD_rank}     = $rank;
    $self->{ASD_fields}   = \@f;
    $self->{ASD_fields_h} = \%fh;
    $self;
}

#---------------

sub boost(;$)
{   my $self = shift;
    @_ or return $self->{ASD_boost};
    my $f = $self->field(shift) or return;
    @_ ? $f->{boost} = shift : $f->{boost};
}

sub fieldNames() { my %c; $c{$_->{name}}++ for shift->fields; sort keys %c }


sub uniqueId() {shift->content($Apache::Solr::uniqueKey)}


sub rank() {shift->{ASD_rank}}


sub fields(;$)
{   my $self = shift;
    my $f    = $self->{ASD_fields};
    @_ or return @$f;
    my $name = shift;
    my $fh   = $self->{ASD_fields_h}{$name};   # grouped by name
    $fh ? @$fh : ();
}


sub field($)
{   my $fh = $_[0]->{ASD_fields_h}{$_[1]};
    $fh ? $fh->[0] : undef;
}


sub content($)
{   my $f = $_[0]->field($_[1]);
    $f ? $f->{content} : undef;
}

our $AUTOLOAD;
sub AUTOLOAD
{   my $self = shift;
    (my $fn = $AUTOLOAD) =~ s/.*\:\://;

      $fn =~ /^_(.*)/    ? $self->content($1)
    : $fn eq 'DESTROY'   ? undef
    : panic "Unknown method $AUTOLOAD (hint: fields start with '_')";
}


sub addField($$%)
{   my $self  = shift;
    my $name  = shift;
    defined $_[0] or return;

    my $field =     # important to minimalize copying of content
      { name    => $name
      , content => ( !ref $_[0]            ? shift
                   : ref $_[0] eq 'SCALAR' ? ${shift()}
                   :                         shift
                   )
      };
    my %args  = @_;
    $field->{boost}  = $args{boost} || 1.0;
    $field->{update} = $args{update};

    push @{$self->{ASD_fields}}, $field;
    push @{$self->{ASD_fields_h}{$name}}, $field;
    $field;
}


sub addFields($%)
{   my ($self, $h, @args) = @_;
    # pass content by ref to avoid a copy of potentially huge field.
    if(ref $h eq 'ARRAY')
    {   for(my $i=0; $i < @$h; $i+=2)
        {   $self->addField($h->[$i] => \$h->[$i+1], @args);
        }
    }
    else
    {   $self->addField($_ => \$h->{$_}, @args) for sort keys %$h;
    }
    $self;
}

#--------------------------

1;
