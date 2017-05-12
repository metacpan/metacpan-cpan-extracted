<%
  use ASP4x::Linker;
  use JSON::XS;
  
  my $linker = ASP4x::Linker->new();
  
  $linker->add_widget(
    name  => "widgetA",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );
  
  $linker->add_widget(
    name  => "widgetB",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );
  
  $linker->add_widget(
    name  => "widgetC",
    attrs => [qw/ size type color /]
  );
  
  $linker->add_widget(
    name  => "widgetD",
    attrs => [qw/ size type color /]
  );
  
  my @result = map {
    my $widget = $_;
    my $res = {
      $widget->name => {
        map { ($_ => $widget->get( $_ )) }
        $widget->attrs
      }
    };
    $res;
  } $linker->widgets;
%><%= JSON::XS->new->utf8->pretty->encode( \@result ) %>
