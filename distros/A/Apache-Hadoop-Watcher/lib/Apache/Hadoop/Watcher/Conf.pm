#
# (C) 2015, Snehasis Sinha
#
package Apache::Hadoop::Watcher::Conf;

use 5.010001;
use strict;
use warnings;

use XML::Twig;
use JSON;

require Apache::Hadoop::Watcher::Base;

our @ISA = qw();
our $VERSION = '0.01';


# methods
sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = {
        url   => 'http://'.($args{'host'}||'localhost').':'.($args{'port'}||'50070').'/conf',
        conf  => undef,
        out   => undef,
    };

    # init
    bless $self, $class;
    $self->_init;
    return $self;
}

# conf xml methods
sub _parse {
    my ($self, %opts) = (@_);
    my ($name, $value, $source);
    my %conf;
    my $twig = new XML::Twig;
       $twig->parse ($opts{'content'});
    
    foreach my $p ( $twig->root->children ('property') ) {
        $name   = ($p->children('name'))[0];
        $value  = ($p->children('value'))[0];
        $source = ($p->children('source'))[0];

        $conf{$name->text} = { value=>$value->text, source=>$source->text };
    }
    $self->{'conf'} = \%conf;
}

sub _init {
    my ($self) = (@_);
    my $base = Apache::Hadoop::Watcher::Base->new;
    $self->_parse (content => $base->_wget (url => $self->{'url'}));
}

# dumps output hashref
sub print {
    my ($self) = (@_);
    Apache::Hadoop::Watcher::Base->new->_print ( output=>$self->{'out'} );
}

# returns output hashref
sub get {
    my ($self) = (@_);
    return $self->{'out'};
}

# search by name, value from current config params
sub search {
    my ($self, %opts) = (@_);
    my $cfg;
    my @keys;
    my $by;

    $by = defined $opts{'by'} ? $opts{'by'} : 'name';
    for ($by) {
        /name/ && do { @keys = grep { /$opts{'pattern'}/i } keys %{$self->{'conf'}}; };
        /value/ && do { @keys = grep { $self->{'conf'}->{$_}->{'value'} =~ m/$opts{'pattern'}/i } keys %{$self->{'conf'}}; };
        /source/ && do { @keys = grep { $self->{'conf'}->{$_}->{'source'} =~ m/$opts{'pattern'}/i } keys %{$self->{'conf'}}; };
    }
    foreach my $name ( @keys ) {
        $cfg->{$name}->{'value'}  = $self->{'conf'}->{$name}->{'value'};
        $cfg->{$name}->{'source'} = $self->{'conf'}->{$name}->{'source'};
    }
    $self->{'out'} = $cfg;
    return $self;
}

1;

__END__

=head1 NAME

Apache::Hadoop::Watcher::Conf - Hadoop configuration monitoring


=head1 SYNOPSIS

  use Apache::Hadoop::Watcher::Conf;
  
  my $w = Apache::Hadoop::Watcher::Conf->new;
  $w->search (pattern=>'sort')->print;

  $w->search (pattern=>'sort', by=>'value')->print;


=head1 DESCRIPTION

This package Apache::Hadoop::Watcher::Conf extracts runtime configuration
parameters and prints them. These parameters can be used for Hadoop
performance tuning and other automations


=head1 SEE ALSO

  Apache::Hadoop::Watcher
  Apache::Hadoop::Watcher::Base
  XML::Twig
  JSON


=head1 AUTHOR

Snehasis Sinha, E<lt>snehasis@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
