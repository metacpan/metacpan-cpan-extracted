package CGI::Application::Plugin::Apache2::Request;
use strict;
use Apache2::Request;
our @ISA = qw(Apache2::Request);
use Apache2::Upload;
use Apache2::Cookie;
use Apache2::URI;

sub new {
    my ($class, @args) = @_;
    return bless {
        r             => Apache2::Request->new(@args),
        __cap_params  => {},
        __cap_deleted => 0,
    }, $class;
}

# we need to implement our own params because Apache2::Request no
# longer allows you to maniu
sub param {
    my ($self, @args) = @_;
    
    # if we don't have anything in %PARAMS, then populate it from args
    my %params = %{$self->{__cap_params}};
    unless( %params or $self->{__cap_deleted} ) {
        foreach my $k ($self->SUPER::param()) {
            my @values = $self->SUPER::param($k);
            $params{$k} = @values > 1 ? \@values : $values[0];
        }
        $self->{__cap_params} = \%params;
    }
    
    # if we just want the value of a param
    if(@args > 1) {
        $params{$args[0]} = $args[1];
        return $self->args->{$args[0]} = $args[1];
    } elsif( @args ) {
        my @result = ref $params{$args[0]} ? @{$params{$args[0]}} : $params{$args[0]};
        return wantarray ?  @result : $result[0];
    } else {
        return keys %params;
    }
}

=pod

=head1 NAME

CGI::Application::Plugin::Apache::Request

=head1 DESCRIPTION

This package is just a wrapper around L<Apache::Request> /
L<Apache2::Request> to add L<CGI.pm|CGI> compatible methods. The interface
and usage is exactly the same as L<CGI.pm|CGI> for the methods provided.

=over 8

=item delete()

=cut

sub delete {
    my ($self, @args) = @_;
    delete $self->{__cap_params}->{$_} foreach (@args);
    $self->{__cap_deleted} = 1;
}

=item delete_all()

=cut

sub delete_all {
    my $self = shift;
    $self->{__cap_params} = {};
    $self->{__cap_deleted} = 1;
}

=item cookie()

=cut

sub cookie {
    my ($self, @args) = @_;
    if($#args == 0) {
        # if we just have a name of a cookie then retrieve the value of the cookie
        my $cookies = Apache2::Cookie->fetch();
        if( $cookies && $cookies->{$args[0]} ) {
            return $cookies->{$args[0]}->value;
        } else {
            return;
        }
    } else {
        # else we have several values so try and create a new cookie
        return Apache2::Cookie->new($self, @args);
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
    my %vars = %{$self->{__cap_params}};

    return wantarray ? %vars : \%vars;
}

=item escapeHTML()

=cut

sub escapeHTML {
    my ($self, $value) = @_;
    require HTML::GenerateUtil;
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

