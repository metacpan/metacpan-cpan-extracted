package Config::Constants::XML::SAX::Handler;

use strict;
use warnings;

our $VERSION = '0.03';

use constant MAX_INCLUDE_DEPTH => 5;

use base 'XML::SAX::Base';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{_config}            = undef;
    $self->{_current_module}    = undef;
    $self->{_current_constant}  = undef; 
    $self->{_constant_deferred} = 0;   
    $self->{_expected_type}     = undef;
    $self->{_current_text}      = undef;
    $self->{_include_depth}     = 0;
    return $self;
}

sub config { (shift)->{_config} }

sub start_element {
    my ($self, $el) = @_;
    my $tag_name = lc($el->{Name});
    if ($tag_name eq 'config') {
        $self->{_config} = {} unless $self->{_config};    
    }
    elsif ($tag_name eq 'include') {
        my $path = $self->_get_value($el, 'path');
        (-e $path)
            || die "Cannot find include file at '$path'";
        ($self->{_include_depth} < $self->MAX_INCLUDE_DEPTH)
            || die "You have reached the max include depth";
        $self->{_include_depth}++;    
        my $p = XML::SAX::ParserFactory->parser(Handler => $self);
        $p->parse_uri($path);        
    }
    elsif ($tag_name eq 'module') {
        $self->{_current_module} = $self->_get_value($el, 'name');
        $self->{_config}->{$self->{_current_module}} = {} 
            unless exists $self->{_config}->{$self->{_current_module}};
    }
    elsif ($tag_name eq 'constant') {
        $self->{_current_constant} = $self->_get_value($el, 'name');
        if (defined($self->_get_value($el, 'value'))) {
            $self->{_config}
                 ->{$self->{_current_module}}
                 ->{$self->{_current_constant}} = $self->_get_value($el, 'value')
        }
        else {
            $self->{_expected_type} = $self->_get_value($el, 'type');
            $self->{_constant_deferred} = 1;
        }
    }
    else {
        die "did not recognize the tag: $tag_name";
    }
}

sub end_element {
    my ($self, $el) = @_;
    return unless lc($el->{Name}) eq 'constant';
    return unless $self->{_constant_deferred};
    ($self->{_current_text})
        || die "We dont have anything to put into the constant '" . $self->{_current_constant} . "'";
    $self->{_config}
         ->{$self->{_current_module}}
         ->{$self->{_current_constant}} = $self->{_current_text};    
    $self->{_current_text}      = undef;
    $self->{_constant_deferred} = 0;
}

sub characters {
    my ($self, $el) = @_;
    my $data = $el->{Data};
    return if $data =~ /^\s+$/;
    if ($self->{_expected_type}) {
        my $value = eval $data;
        die "eval of constant value failed: '$data' -> $@" if $@;
        (UNIVERSAL::isa($value, $self->{_expected_type}))
            || die "constant did not eval into the type we expected ($data); got : '$value' - expected: '" . $self->{_expected_type}. "'";
        $self->{_current_text} = $value;
    }
    else {
        # its just plain text
        $self->{_current_text} = $data;
    }
}

sub _get_value {
    my ($self, $el, $key) = @_;
    return undef unless exists $el->{Attributes}->{'{}' . $key};
    return $el->{Attributes}->{'{}' . $key}->{Value};        
}

1;

__END__


=head1 NAME

Config::Constants::XML::SAX::Handler - XML::SAX::Handler for Config::Constants::XML

=head1 SYNOPSIS
  
  use Config::Constants::XML::SAX::Handler;

=head1 DESCRIPTION

Nothing to see here, move along, move along.

=head1 METHODS

=over 4

=item B<new>

=item B<config>

=item B<start_element>

=item B<end_element>

=item B<characters>

=back

=head1 TO DO

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, see the L<Config::Constants> module for more information.

=head1 SEE ALSO

=over 4

=item L<XML::SAX::Base>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

