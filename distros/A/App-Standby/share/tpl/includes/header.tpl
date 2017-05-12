<!doctype html>  
<html lang="en">
<head>
  <meta charset="utf-8">

  <!-- Always force latest IE rendering engine (even in intranet) & Chrome Frame 
       Remove this if you use the .htaccess -->
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">

  <title>[% title | l10n %]</title>
  <meta name="description" content="[% product %] Web Management Interface">
  <meta name="author" content="[% product %] by Dominik Schulz">

  <!--  Mobile viewport optimized: j.mp/bplateviewport -->
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

   <link href="css/bootstrap.min.css" rel="stylesheet">
   <style type="text/css">
      body {
         padding-top: 60px;
         padding-bottom: 40px;
      }
   </style>
   <link href="css/bootstrap-responsive.min.css" rel="stylesheet">
</head>

<body>

[% IF nonavigation != 1 %]
[% INCLUDE includes/navigation.tpl %]
[% END %]

