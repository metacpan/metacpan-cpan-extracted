package CGI::Application::Plugin::Apache::Request;
use strict;
use HTML::GenerateUtil;
use base 'Apache::Request';
use Apache::Request;
use Apache::Cookie;
use Apache::URI;

sub new {
    my($class, @args) = @_;
    return bless $class->SUPER::new(@args), $class;
}

=pod

=head1 NAME

CGI::Application::Plugin::Apache::Request

=head1 DESCRIPTION

This package is just a wrapper around Apache::Request to add L<CGI.pm|CGI> compatible
methods. The interface and usage is exactly the same as L<CGI.pm|CGI>.

=over 8

=item delete()

=cut

sub delete {
    my ($self, @args) = @_;
    my $table = $self->parms();
    foreach my $arg (@args) {
        delete $table->{$arg};
    }
}

=item delete_all()

=cut

sub delete_all {
    my $self = shift;
    my $table = $self->parms();
    my @args = keys %$table;
    foreach my $arg (@args) {
        delete $table->{$arg};
    }
}

=item cookie()

=cut

sub cookie {
    my ($self, @args) = @_;
    if($#args == 0) {
        # if we just have a name of a cookie then retrieve the value of the cookie
        my $cookies = Apache::Cookie->fetch();
        if( $cookies && $cookies->{$args[0]} ) {
            return $cookies->{$args[0]}->value;
        } else {
            return;
        }
    } else {
        # else we have several values so try and create a new cookie
        return Apache::Cookie->new($self, @args);
    }
}

=item Dump()

=cut

sub Dump {
    my $self = shift;
    my($param,$value,@result);
    return '<ul></ul>' unless $self->param;
    push(@result,"<ul>");
    foreach $param ($self->param) {
        my $name = $self->escapeHTML($param);
        push(@result,"<li><strong>$name</strong></li>");
        push(@result,"<ul>");
        foreach $value ($self->param($param)) {
            $value = $self->escapeHTML($value);
            push(@result,"<li>$value</li>");
        }
        push(@result,"</ul>");
    }
    push(@result,"</ul>");
    return join("\n",@result);
}

=item Vars()

=cut

sub Vars {
    my $self = shift;
    my @params = $self->param();
    my %Vars = ();
    foreach my $param (@params) {
        my @values = $self->param($param);
        if( scalar @values == 1 ) {
            $Vars{$param} = $values[0];
        } else {
            $Vars{$param} = \@values;
        }
    }

    if(wantarray) {
        return %Vars;
    } else {
        return \%Vars;
    }
}

=item escapeHTML()

=cut

sub escapeHTML {
    my ($self, $value) = @_;
    $value = HTML::GenerateUtil::escape_html($value, 
        (
            $HTML::GenerateUtil::EH_LFTOBR 
            | $HTML::GenerateUtil::EH_SPTONBSP 
            | $HTML::GenerateUtil::EH_LEAVEKNOWN
        )
    ); 
    return $value;
}

=item upload()

=cut

sub upload {
    my ($self, $file) = @_;
    # if they want a specific one, then lets give them the file handle
    if( $file ) {
        my $upload = $self->SUPER::upload($file);
        if( $upload ) {
            return $upload->fh();
        } else {
            return;
        }
    # else they want them all
    } else {
        my @files = $self->SUPER::upload();
        @files = map { $self->SUPER::upload($_)->fh() } @files;
        return @files;
    }
}

1;

__END__

=item 

=back

Please see L<CGI::Application::Plugin::Apache> for more details.

