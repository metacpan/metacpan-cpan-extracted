#!/usr/bin/perl
use File::Path qw(make_path);
use strict;
use warnings;

our $open_t = '<%';
our $close_t = '%>';

sub create_cart_layout;
sub create_products_view;
sub create_cart_view;
sub create_checkout_view;
sub create_receipt_view;
sub create_shipping_view;
sub create_billing_view;
sub create_review_view;
sub create_receipt_view;


# (1) quit unless we have the correct number of command-line args
if ($ARGV[0] and ($ARGV[0] eq '-h' or $ARGV[0] eq '--help')) {
    print "\nUsage: ./bin/create_cart_views.pl open_tag_def close_tag_def \n";
    print "\ntag_def is the open and close tag for the template, by default open_tag_def is <%  and close_tag_def is %>\n";
    print "\n e.g. ./bin/create_views.pl '<%' '%>'\n";
    exit;
}
$open_t =  $ARGV[0] || $open_t;
$close_t =  $ARGV[1] || $close_t;
 
my $dir = 'views';

if (-e $dir and -d $dir) {
  make_path('views/cart/');
  print "Creating views/cart directory\n";
  make_path('views/layouts/');
  print "Creating views/layouts directory\n";
	create_cart_layout;
	print "Layout created at $dir/layouts/cart.tt\n";
  create_products_view;
  print "Products view created at $dir/products.tt\n";
  create_cart_view;
  print "Cart view created at $dir/cart/cart.tt\n";
  create_shipping_view;
  print "Shipping view created at $dir/cart/shipping.tt\n";
  create_billing_view;
  print "Billing view created at $dir/cart/billing.tt\n";
  create_review_view;
  print "Review view created at $dir/cart/review.tt\n"; 
  create_receipt_view;
  print "Receipt view created at $dir/cart/receipt.tt\n"; 
} 
else {
  print "view directory needs to exists in order to proceed, please be sure you are in the root of your application.\n";
}



sub create_cart_layout{
  my $page = "";
  $page .= "
		<!DOCTYPE html>
		<html lang='en'>
		<head>
			<meta name='viewport' content='width=device-width, initial-scale=1.0, user-scalable=yes'>
			<title>Ec Cart</title>
			<link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css'>
			<script src='https://code.jquery.com/jquery-2.2.4.min.js'></script>
			<script src='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js'></script>
		</head>
		<body>
  <nav class='navbar navbar-default'>
    
      <div class='navbar-header'>
        <button type='button' class='navbar-toggle collapsed' data-toggle='collapse' data-target='#menu-options' aria-expanded='false'>
          <span class='sr-only'>Toggle navigation</span>
          <span class='icon-bar'></span>
          <span class='icon-bar'></span>
          <span class='icon-bar'></span>
        </button>
        <a class='navbar-brand' href='#'>Ec-Cart</a>
      </div>
    </div>
    <div class='collapse navbar-collapse' id='menu-options'>
      <ul class='nav navbar-nav navbar-right'>
        <li><a href='/products'>Products</a></li>
        <li><a href='/cart'><span class='glyphicon glyphicon-shopping-cart' aria-hidden='true'></span></a></li>
         <li class='dropdown'>
          <a href='#' class='dropdown-toggle' data-toggle='dropdown' role='button' aria-haspopup='true' aria-expanded='false'>About<span class='caret'></span></a>
          <ul class='dropdown-menu'>
            <li><a href='https://github.com/YourSole/Cart'>Github</a></li>
          </ul>
        </li>
      </ul>
</nav>
			<div class='container'>
				$open_t content $close_t 
			</div>
		</body>
		</html>
	";
  create_view( 'layouts/cart.tt', $page );
  return 1;
};


sub create_products_view{
  my $page = "";
  $page .= "
  <h1>Product list</h1>
  <table class='table table-bordered'>
    <thead>
      <tr>
        <th>Sku</th><th>Price</th><th>Action</th>
      </tr>
    </thead>
    <tbody>";
    $page .= "
    $open_t FOREACH product IN product_list $close_t
      <tr>
        <td> $open_t product.ec_sku $close_t </td>
        <td> $open_t product.ec_price $close_t </td>
        <td>
          <form method='post' action='cart/add'>
            <input type='hidden' name='ec_sku' value='$open_t product.ec_sku $close_t'>
            <input type='hidden' name='ec_quantity' value='1'>
            <input type='submit' value = 'Add' class='btn btn-primary'>
          </form>
        </td>
      </tr>
    $open_t END $close_t";
  $page .= "
    </tbody>
  </table>";
  create_view( 'products.tt', $page );
  return 1;
};


sub _cart_view {
  my ($params) = @_;
  my $editable = $params->{editable} || 0;
  my $ec_cart = $params->{ec_cart} || 'ec_cart';
  my $colspan = $editable?4:2;
  my $page = "$open_t IF $ec_cart.cart.items.size $close_t";
    $page .= "<h2>Cart info</h2>
    <table class='table table-bordered'>
      <thead>
        <tr>
          <th>SKU</th>";
          $page .= '<th></th>' if $editable == 1;
          $page .= "<th>Quantity</th>";
          $page .= '<th></th>' if $editable == 1;
          $page .= "<th>Price</th>
        </tr>
      </thead>
      <tbody>
    $open_t FOREACH item IN $ec_cart.cart.items $close_t
        <tr>
          <td>  $open_t item.ec_sku $close_t </td>";
      if( $editable == 1 ){
        $page .="
          <td><form method='post' action='cart/add'>
          <input type='hidden' name='ec_sku' value='$open_t item.ec_sku $close_t'>
          <input type='hidden' name='ec_quantity' value='-1'>
          <input type='submit' value = '-1' class='btn btn-primary'>
          </form></td>";
      }    
      $page .="
          <td>$open_t item.ec_quantity  $close_t </td>";
      if( $editable == 1 ){
        $page .= "<td><form method='post' action='cart/add'>
            <input type='hidden' name='ec_sku' value='$open_t item.ec_sku $close_t'>
            <input type='hidden' name='ec_quantity' value='1'>
            <input type='submit' value = '+1' class='btn btn-primary'>
            </form></td>";
        }
        $page .="<td>$open_t item.ec_price $close_t </td>
        </tr>
    $open_t END $close_t
        <tr>
          <td colspan=$colspan align='right'>Subtotal</td><td>$open_t $ec_cart.cart.subtotal $close_t</td>
        </tr>
      $open_t FOREACH adjustment IN $ec_cart.cart.adjustments $close_t
        <tr><td colspan=$colspan align='right'>$open_t adjustment.description $close_t</td><td>$open_t adjustment.value $close_t</td></tr> 
      $open_t END $close_t 
      </tbody>
      <tfoot>
        <tr>
          <td colspan=$colspan>Total</td><td> $open_t $ec_cart.cart.total $close_t </td>
        </tr>
      </tfoot>
    </table>
    $open_t FOREACH error = $ec_cart.add.error $close_t
      <p> $open_t error $close_t </p>
    $open_t END $close_t";

    if ( $editable ){
      $page .= "$open_t IF $editable $close_t
       <p><a href='cart/clear'> Clear your cart. </a></p>
      $open_t END $close_t";
    }

  $page .= "$open_t ELSE $close_t
    <p>Your cart is empty</p>
  $open_t END $close_t";

  $page;
}

sub create_cart_view{
  my $page = "";

  $page .= _cart_view({ editable => 1 });
  $page .= "$open_t IF ec_cart.cart.items.size > 0 $close_t <p><a href='cart/shipping'> Checkout </a></p>$open_t END $close_t
  <p> <a href='products'>Continue shopping</a></p>";
  create_view( 'cart/cart.tt', $page );
  return 1;

};

sub create_shipping_view{
  my ($params) = @_;
  my $ec_cart = $params->{ec_cart} || 'ec_cart';
  my $page ="<h1>Shipping</h1>";
  $page .= _cart_view;
  $page .= "$open_t IF $ec_cart.cart.items.size $close_t";
  $page .= "
  $open_t FOREACH error = ec_cart.shipping.error $close_t
    <p> $open_t error $close_t </p>
  $open_t END $close_t
  <h2>Shipping info</h2>
  <form method='post' action='shipping'>
    <fieldset class='form-group'>
      <label for='email'>Email address</label>
      <input type='email' name='email' class='form-control' value='$open_t ec_cart.shipping.form.email $close_t' placeholder='email\@domain.com' required >
      <small class='text-muted'>We'll never share your email with anyone else.</small>
    </fieldset>
    <a href='../cart' class='btn btn-primary'>Back</a>
    <input type='submit' value = 'Continue' class='btn btn-primary'>
  </form>";
  
	$page .= "$open_t END $close_t";
  create_view( 'cart/shipping.tt', $page );
}

sub create_billing_view{
  my ($params) = @_;
  my $ec_cart = $params->{ec_cart} || 'ec_cart';
  my $page .= "<h1>Billing</h1>";
  $page .= _cart_view;
  $page .= "$open_t IF $ec_cart.cart.items.size $close_t";
  $page .= "
  $open_t FOREACH error = ec_cart.billing.error $close_t
    <p> $open_t error $close_t </p>
  $open_t END $close_t
  <h2>Billing info</h2>
  <form method='post' action='billing'>
    <fieldset class='form-group'>
      <label for='email'>Email address</label>
      <input type='email' name='email' class='form-control' value='$open_t ec_cart.billing.form.email $close_t' placeholder='email\@domain.com' required >
      <small class='text-muted'>We'll never share your email with anyone else.</small>
    </fieldset>
    <a href='shipping' class='btn btn-primary'>Back</a>
    <input type='submit' value = 'Continue' class='btn btn-primary'>
  </form>";
	$page .= "$open_t END $close_t";
  create_view( 'cart/billing.tt', $page );
}

sub create_review_view{
  my ($params) = @_;
  my $ec_cart = $params->{ec_cart} || 'ec_cart';
  my $page = "";
  $page .= "
  <h1>Review</h1>";
  $page .= _cart_view;
  $page .= "$open_t IF $ec_cart.cart.items.size $close_t";
  $page .= "<table class='table table-bordered'>
      <tr><td>Shipping <a href='shipping' class='btn btn-primary'>edit</a></td><td>$open_t ec_cart.shipping.form.email $close_t</td></tr>
      <tr><td>Billing <a href='billing' class='btn btn-primary'>edit</a></td><td>$open_t ec_cart.billing.form.email $close_t</td></tr>
  </table>
  <form method='post' action='checkout'>
  <p>
    <a href='billing' class='btn btn-primary'>Back</a>
    <input type='submit' value = 'Place Order' class='btn btn-primary'>
  </p>
  </form>";
	$page .= "$open_t END $close_t";
  create_view( 'cart/review.tt', $page );
}

sub create_receipt_view{
  my ($params) = @_;
  my $ec_cart = $params->{ec_cart} || 'ec_cart';
	my $page .= '<h1>Receipt</h1>';
  $page .= _cart_view;
  $page .= "$open_t IF $ec_cart.cart.items.size $close_t";
  $page .="
  <p>Checkout has been successful!!</p>
  <h2>Receipt #: $open_t $ec_cart.cart.session $close_t </h2>
  ";
  $page .= "
  <h2>Log Info</h2>
  <table class='table table-bordered'>
    <tr><td>Session:</td><td>$open_t  $ec_cart.cart.session $close_t</td></tr>
    <tr><td>Email</td><td> $open_t $ec_cart.shipping.form.email $close_t </td>
  </table>
  <p><a href='../products'> Product index </a></p>";
	$page .= "$open_t END $close_t";
  create_view( 'cart/receipt.tt', $page );
}

sub create_view{
  my ($name, $body) = @_;
  my $filename = "views/$name";
  open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
  print $fh $body;
  close $fh;
};

1;
