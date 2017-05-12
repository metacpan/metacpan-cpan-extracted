#MLP neural network in Java
#by Phil Brierley
#www.philbrierley.com
#This code may be freely used and modified at will
###########################
#Translated into perl - ccolbourn oct 2004

my $numEpochs = 500;
my $numInputs = 3;
my $numHidden = 4;
my $numPatterns = 4;
my $LR_IH = 0.7;
my $LR_HO = 0.07;

my $patNum;
my $errThisPat;
my $outPred;
my $RMSerror;

my @trainInputs;
my @trainOutput;


# the outputs of the hidden neurons
my @hiddenVal;

# the weights
my @weightsIH;
my @weightsHO;


main();


#==============================================================
#********** THIS IS THE MAIN PROGRAM **************************
#==============================================================

sub main
 {

 # initiate the weights
  initWeights();

 # load in the data
  initData();

 # train the network
    for(my $j = 0;$j <= $numEpochs;$j++)
    {

        for(my $i = 0;$i<$numPatterns;$i++)
        {

            #select a pattern at random
            $patNum = (rand()*$numPatterns)-0.001;

            #calculate the current network output
            #and error for this pattern
            calcNet();

            #change network weights
            WeightChangesHO();
            WeightChangesIH();
        }

        #display the overall network error
        #after each epoch
        calcOverallError();

        print "epoch = ".$j."  RMS Error = ".$RMSerror."\n";

    }

    #training has finished
    #display the results
    displayResults();

 }

#============================================================
#********** END OF THE MAIN PROGRAM **************************
#=============================================================






#***********************************
sub calcNet()
 {
    #calculate the outputs of the hidden neurons
    #the hidden neurons are tanh

    for(my $i = 0;$i<$numHidden;$i++)
    {
	$hiddenVal[$i] = 0.0;

        for(my $j = 0;$j<$numInputs;$j++)
	{
        $hiddenVal[$i] = $hiddenVal[$i] + ($trainInputs[$patNum][$j] * $weightsIH[$j][$i]);
	}

        $hiddenVal[$i] = tanh($hiddenVal[$i]);
    }

   #calculate the output of the network
   #the output neuron is linear
   $outPred = 0.0;

   for(my $i = 0;$i<$numHidden;$i++)
   {
    $outPred = $outPred + $hiddenVal[$i] * $weightsHO[$i];
   }
    #calculate the error
    $errThisPat = $outPred - $trainOutput[$patNum];
 }


#************************************
 sub WeightChangesHO()
 #adjust the weights hidden-output
 {
   for(my $k = 0;$k<$numHidden;$k++)
   {
    $weightChange = $LR_HO * $errThisPat * $hiddenVal[$k];
    $weightsHO[$k] = $weightsHO[$k] - $weightChange;

    #regularisation on the output weights
    if ($weightsHO[$k] < -5)
    {
        $weightsHO[$k] = -5;
    }
    elsif ($weightsHO[$k] > 5)
    {
        $weightsHO[$k] = 5;
    }
   }
 }


#************************************
 sub WeightChangesIH()
 #adjust the weights input-hidden
 {
  for(my $i = 0;$i<$numHidden;$i++)
  {
   for(my $k = 0;$k<$numInputs;$k++)
   {
    my $x = 1 - ($hiddenVal[$i] * $hiddenVal[$i]);
    $x = $x * $weightsHO[$i] * $errThisPat * $LR_IH;
    $x = $x * $trainInputs[$patNum][$k];
    my $weightChange = $x;
    $weightsIH[$k][$i] = $weightsIH[$k][$i] - $weightChange;
   }
  }
 }


#************************************
 sub initWeights()
 {

  for(my $j = 0;$j<$numHidden;$j++)
  {
    $weightsHO[$j] = (rand() - 0.5)/2;
    for(my $i = 0;$i<$numInputs;$i++)
    {
    $weightsIH[$i][$j] = (rand() - 0.5)/5;
    }
  }

 }


#************************************
 sub initData()
 {

    print "initialising data\n";

    # the data here is the XOR data
    # it has been rescaled to the range
    # [-1][1]
    # an extra input valued 1 is also added
    # to act as the bias

    $trainInputs[0][0]  = 1;
    $trainInputs[0][1]  = -1;
    $trainInputs[0][2]  = 1;    #bias
    $trainOutput[0] = 1;

    $trainInputs[1][0]  = -1;
    $trainInputs[1][1]  = 1;
    $trainInputs[1][2]  = 1;       #bias
    $trainOutput[1] = 1;

    $trainInputs[2][0]  = 1;
    $trainInputs[2][1]  = 1;
    $trainInputs[2][2]  = 1;        #bias
    $trainOutput[2] = -1;

    $trainInputs[3][0]  = -1;
    $trainInputs[3][1]  = -1;
    $trainInputs[3][2]  = 1;     #bias
    $trainOutput[3] = -1;

 }


#************************************
 sub tanh()
 {


	my $x = shift;

    if ($x > 20){ return 1;}
    elsif ($x < -20){ return -1;}
    else
        {
        my $a = exp($x);
        my $b = exp(-$x);
        return ($a-$b)/($a+$b);
        }
 }


#************************************
 sub displayResults()
    {
     for(my $i = 0;$i<$numPatterns;$i++)
        {
        $patNum = $i;
        calcNet();
        print "pat = ".($patNum+1)." actual = ".$trainOutput[$patNum]." neural model = ".$outPred."\n";
        }
    }


#************************************
sub calcOverallError()
    {
     $RMSerror = 0.0;
     for(my $i = 0;$i<$numPatterns;$i++)
        {
        $patNum = $i;
        calcNet();
        $RMSerror = $RMSerror + ($errThisPat * $errThisPat);
        }
     $RMSerror = $RMSerror/$numPatterns;
     $RMSerror = sqrt($RMSerror);
    }





