package Data;
our $test1 = <<"TEST1";
<!DOCTYPE html>
<html lang="en">

<head>
  <title></title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="http://localhost/css/style.css">
  <link rel="stylesheet" href="http://localhost/javascripts/jquery-ui-1.12.1.custom/jquery-ui.min.css">
</head>

<body>
    booya
<ul>
	<li class="active">My Menu Item<ul>
			<li class="active">A Tom Tom<ul>
					<li class="active">One<ul>
							<li class="active">Baloney pony<ul>
									<li class="active">Deep One</li>
								</ul>
							</li>
						</ul>
					</li>
				</ul>
			</li>
			<li class="">Dinky</li>
			<li class="">Nut</li>
		</ul>
	</li>
</ul>

</body>
</html>
TEST1

our $test2 = <<"TEST2";
<!DOCTYPE html>
<html lang="en">

<head>
  <title></title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="http://localhost/css/style.css">
  <link rel="stylesheet" href="http://localhost/javascripts/jquery-ui-1.12.1.custom/jquery-ui.min.css">
</head>

<body>
    went_down
<ul>
	<li class="active">My Menu Item<ul>
			<li class="">A Tom Tom<ul>
					<li class="">One<ul>
							<li class="">Baloney pony<ul>
									<li class="">Deep One</li>
								</ul>
							</li>
						</ul>
					</li>
				</ul>
			</li>
			<li class="">Dinky</li>
			<li class="">Nut</li>
		</ul>
	</li>
</ul>

</body>
</html>
TEST2
