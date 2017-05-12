sub _products_view{
  my ($params) = @_;
  my $products = $params->{product_list};
  my $page ="";
  $page .= "
  <h1>Product list</h1>
  <table>
    <thead>
      <tr>
        <th>Sku</th><th>Price</th><th>Action</th>
      </tr>
    </thead>
    <tbody>";
  foreach my $product (@{$products}) {
    $page .= "
      <tr>
        <td>".$product->{ec_sku}."</td>
        <td>".$product->{ec_price}."</td>
        <td>
          <form method='post' action='cart/add'>
            <input type='hidden' name='ec_sku' value='".$product->{ec_sku}."'>
            <input type='hidden' name='ec_quantity' value='1'>
            <input type='submit' value = 'Add'>
          </form>
        </td>
      </tr>";
  };
  $page .= "
    </tbody>
  </table>";
  $page;
}

sub _cart_view{
  my ($params) = @_;
  my $page = "";
  my $ec_cart = $params->{ec_cart};
  if ( $ec_cart->{add}->{error} ){
    foreach my $error ( @{$ec_cart->{add}->{error}} ){
      $page .= "<p>".$error."</p>";
    }
  }
  $page .=  "<h1>Cart</h1>\n";
  $page .= _cart_info({ ec_cart => $ec_cart, editable => 1 });
  $page .= "\n<p><a href='cart/clear'> Clear your cart. </a></p>";
  $page .= "<a href='products'> Continue shopping. </a>\n";
  $page .= "\n<p><a href='cart/shipping'> Checkout. </a></p>";
  $page;
}

sub _cart_info{
  my ($params) = @_;
  my $ec_cart = $params->{ec_cart};
  my $editable = $params->{editable};

  my $page = "";
  if (@{$ec_cart->{cart}->{items}} > 0 ) {
    $page .= "
    <table>
      <thead>
        <tr>
          <th>SKU</th><th></th><th>Quantity</th><th></th><th>Price</th>
        </tr>
      </thead>
      <tbody>";
    foreach my $item (@{$ec_cart->{cart}->{items}}){
      $page .= "
        <tr>
          <td>".$item->{ec_sku}."</td>
          <td>";
          if( $editable == 1 ) {
              $page .= "<form method='post' action='cart/add'>
            <input type='hidden' name='ec_sku' value='".$item->{ec_sku}."'>
            <input type='hidden' name='ec_quantity' value='-1'>
            <input type='submit' value = '-1'>
            </form>" 
          }
          $page .= "</td>
          <td>". $item->{ec_quantity} ."</td>
          <td>";
          if( $editable == 1 ){
            $page .= "<form method='post' action='cart/add'>
            <input type='hidden' name='ec_sku' value='".$item->{ec_sku}."'>
            <input type='hidden' name='ec_quantity' value='1'>
            <input type='submit' value = '+1'>
            </form>";
          }
          $page .= "</td>
          <td>".$item->{ec_price}."</td>
        </tr>";
    }
    $page .= "
      </tbody>
      <tfoot>
        <tr>
          <td colspan=4>Subtotal</td><td>".$ec_cart->{cart}->{subtotal}."</td>
        </tr>
      </tfoot>
    </table>";


    $page .= '<table>
      <tbody>';
    
    foreach my $adjustment (@{$ec_cart->{cart}->{adjustments}}){
      $page .= "<tr><td colspan=4>".$adjustment->{description}."</td><td>".$adjustment->{value}."</td></tr>"; 
    }

    $page .= "
      </tbody>
      <tfoot>
        <tr>
          <td colspan=4>Total</td><td>".$ec_cart->{cart}->{total}."</td>
        </tr>
      </tfoot>
    </table>";

  }
  else{
    $page .= "Your cart is empty.";
  }
  $page;
}


sub _shipping_view{
  my ($params) = @_;
  my $ec_cart = $params->{ec_cart};

  my $page ="";

  $page .= "
  <h1>Shipping</h1>";
  $page .= _cart_info({ ec_cart => $ec_cart });
  $page .= "<p><a href='clear'> Clear your cart. </a></p>";
  $page .= "<p><a href='../cart'>Cart</a></p>";
  if ( $ec_cart->{shipping}->{error} ){
    foreach my $error ( @{$ec_cart->{shipping}->{error}} ){
      $page .= "<p>".$error."</p>";
    }
  }
  $page .= "
    
    <p>Shipping info</p>
    <form method='post' action='shipping'>
     Email <input type='email' name='email' value='".$ec_cart->{shipping}->{form}->{email}."' paceholder='email\@domain.com' required>
      <input type='submit' value = 'Continue'>
    </form>";
}

sub _billing_view{
  my ($params) = @_;
  my $ec_cart = $params->{ec_cart};

  my $page ="";

  $page .= "
  <h1>Billing</h1>";
  $page .= _cart_info({ ec_cart => $ec_cart });
  $page .= "\n<p><a href='clear'> Clear your cart. </a></p>";
  $page .= "<p><a href='shipping'>Shipping</a></p>";

  if ( $ec_cart->{billing}->{error} ){
    foreach my $error ( @{$ec_cart->{billing}->{error}} ){
      $page .= "<p>".$error."</p>";
    }
  }
  $page .= "
    <p>Billing info</p>
    <form method='post' action='billing'>
     Email <input type='email' name='email' value='".$ec_cart->{billing}->{form}->{email}."' paceholder='email\@domain.com' required>
      <input type='submit' value = 'Continue'>
    </form>";

};

sub _review_view{
  my ($params) = @_;
  my $ec_cart = $params->{ec_cart};

  $page = "
    <h1>Review</h1>";
  $page .= _cart_info({ ec_cart => $ec_cart });
  $page .= "\n<p><a href='cart/clear'> Clear your cart. </a></p>";
  $page .="<table>
      <tr><td>Shipping - email</td><td>".$ec_cart->{shipping}->{form}->{email}."</td></tr>
      <tr><td>Billing - email</td><td>".$ec_cart->{billing}->{form}->{email}."</td></tr>
    </table>
    <p>Edit <a href='shipping'>Shipping</a></p>
    <p>Edit <a href='billing'>Billing</a></p>
    <form method='post' action='checkout'>
    <input type='submit' value = 'Place Order'>
    </form>";
  
};


sub _receipt_view{
  my ($params) = @_;
  my $ec_cart = $params->{ec_cart};
  my $page = "";

  $page .= "
  <p>Checkout has been successful!!</p>
  <h1>Receipt #: ".$ec_cart->{cart}->{session}." </h1>";
  $page .= _cart_info({ ec_cart => $ec_cart });
  $page .= "<h2>Log Info</h2>
  <table>
    <tr><td>Session :</td><td>".$ec_cart->{cart}->{session}."</td></tr>
    <tr><td>Email</td><td>".$ec_cart->{shipping}->{form}->{email}."</td>
  </table>
  <p> <a href='../products'>Go to products</a> </p>";
  $page;  
};

1;
