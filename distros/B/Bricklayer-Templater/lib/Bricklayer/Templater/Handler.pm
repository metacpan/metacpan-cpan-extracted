# Bricklayer Plugin SuperClass
package Bricklayer::Templater::Handler;

use Carp;

=head1 NAME

Bricklayer::Templater::Handler - Base class for all Template tag handlers

=head1 SYNOPSIS

=head1 DESCRIPTION

Bricklayer::Templater::Handler does all the common heavy lifting that a Template tag handler needs to do. It initialize the handler object and sets up the callback hooks that are needed.

=head2 The Handler API.

=head3 Handler object attributes

=over 1

=item app
    
    $self->app() returns the template engine

=item attributes
    
    $self->attributes() returns a hashref of tag attributes. tag attributes are specified the same way
    that xml attributes are with the following restrictions.

=over 2

=item attribute values must be enclosed in double quotes

=item 

=back

=item block
    
    $self->block() returns the text block contents of the tag. The bricklayer parser is not recursive
    on its own. If you tag is expected to process the block as more template text then you should call
    parse_block() as shown below.
    
=item type
    
    $self->type() returns the tag type. This shoule be either 'block' or 'single' or 'text'. You
    probably will never need to use this.

=item tagname
    
    $self->tagname() returns the tag's name. This should be the classname minus the 
    Bricklayer::Templater::Handler:: part.

=item tagid
    
    $self->tagid() returns the template engines current template tag identifier. It is equivalent to
    calling $self->app()->identifier.

=back

=head3 handler object Methods

=over 1

=item load

    Bricklayer::Templater::Handler::tag::name->load() is the constructor for a tag handler.
    it will get passed a Token data structure and the Template engine object as a context.
 
=item parse_block

    $self->parse_block($arg) is a convenience function that will run the templater on the block with
    any argument you pass in to it.

=item run_handler

    $handler->run_handler() is what the engine calls to actually run the handler. You probably
    shouldn't be using this method since it's mostly for internal use.

=back

=cut

# Initialization
sub load {
	my $PluginObj = {Token => $_[1],
					 App => $_[2],
					 err => undef
					 };
	
    croak "ahhh didn't get passed the Token object" unless $_[1];
    croak "ahhh didn't get passed the context object" unless $_[2];
    $PluginObj = bless($PluginObj, $_[0]);

	$PluginObj->load_extra()
        if $PluginObj->can('load_extra'); # optional method for handlers
	
	return $PluginObj;
}

sub attributes {
	return $_[0]->{Token}{attributes};
}

sub block {
	return $_[0]->{Token}{block};
}

sub type {
	return $_[0]->{Token}{type};
}

sub tagname {
	return $_[0]->{Token}{tagname};
}

sub tagid {
	return $_[0]->app()->identifier();
}

sub app {
    return $_[0]->{App};
}

sub parse_block {
	$_[0]->app->run_sequencer($_[0]->block(), $_[1]);
	return ;
}

sub run_handler {
	my $result = $_[0]->run($_[1]);
	$_[0]->app()->publish($result);
}

return 1;
