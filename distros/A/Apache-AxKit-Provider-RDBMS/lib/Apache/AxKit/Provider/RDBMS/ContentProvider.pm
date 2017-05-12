package Apache::AxKit::Provider::RDBMS::ContentProvider;

use strict;

sub new {
    my $class = shift;
    my $this  = { apache => shift };
    
    bless $this, $class;
    
    $this->init();
    
    return $this;
}

sub init {
}

sub getContent {
    throw Apache::AxKit::Exception::Error( -text => "subclasses must implement this method" );
}

1;