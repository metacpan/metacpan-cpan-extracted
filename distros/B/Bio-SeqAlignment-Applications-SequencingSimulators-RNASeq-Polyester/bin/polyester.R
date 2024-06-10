## dependencies - note that these will be loaded upon startup from the cmdline
## only listed here for completeness
library(getopt)
library(polyester)
library(utils)

################################################################################
## Specify command line arguments
spec = matrix(c( 
## Column 1  : long option name
## Column 2  : short option name
## Column 3  : 0 : no argument, 1 : required argument 2 : optional argument
## Column 4  : one of logical, integer, double, complex, character
  
  'bias'       , 'b' , 2,  'character' ,  ## fragment selection bias
  'errormodel' , 'e' , 2 , 'character' ,  ## error model
  'errorrate'  , 'E' , 2 , 'double'    ,  ## error probability
  'fastafile'  , 'f' , 1 , 'character' ,  ## fasta file (path)
  'fcfile'     , 'c' , 2 , 'character' ,  ## fold change (path)
  'gcbias'     , 'g' , 2 , 'integer'   ,  ## gc bias
  'numreps'    , 'n' , 2 , 'character' ,  ## num of replicates in each group
  'outdir'     , 'o' , 2 , 'character' ,  ## path to output directory
  'paired'     , 'p' , 2 , 'logical' ,    ## paired reads
  'readsfile'  , 'r' , 1 , 'character' ,  ## reads_per_transcript (path)
  'readlen'    , 'R' , 2 , 'integer'   ,  ## read length
  'fraglen'    , 'F' , 2 , 'integer'   ,  ## fragment length (avg)
  'fragsd'     , 'S' , 2 , 'integer'   ,  ## fragment length (sd)
  'seed'       , 'd' , 2 , 'integer'   ,  ## random seed
  'strandspec' , 's' , 2 , 'logical'   ,  ## strand specificity
  'writeinfo'  , 'w' , 2 , 'logical'      ## save simulation info? 
),byrow=TRUE,ncol = 4)

################################################################################
## process commandline arguments

opt = getopt(spec)


## check that all mandatory inputs have been provided
if(is.null(opt$fastafile)) {
  cat("No fasta file provided. Will exit now.")
  quit(save="no",status=1)
}
if(is.null(opt$readsfile)) {
  cat("No transcript read count file provided. Will exit now.")
  quit(save="no",status=1)
}

## (sensible?) default for some optional parameters
if(is.null(opt$bias)) opt$bias <- 'none'
if(is.null(opt$errormodel)) opt$errormodel <- 'uniform'
if(is.null(opt$errorrate))  opt$errorrate <- 0.005
if(is.null(opt$fraglen))    opt$fraglen <-250
if(is.null(opt$fragsd))     opt$fragsd <-25
if(is.null(opt$gcbias))     opt$gcbias <- 0
if(is.null(opt$outdir))     opt$outdir <- '.'
if(is.null(opt$paired))     opt$paired <- FALSE
if(is.null(opt$readlen))    opt$readlen <- 100
if(is.null(opt$seed))       opt$seed <- 12345
if(is.null(opt$strandspec)) opt$strandspec <- FALSE
if(is.null(opt$writeinfo))  opt$writeinfo <- TRUE
## defaults for some options that may be included in the future
if(is.null(opt$distr))      opt$distr <- 'normal'
if(is.null(opt$meanmodel))  opt$meanmodel <- FALSE

## check for valid parameters
if (! is.element(opt$gcbias, 0:7) ) {
  cat("gcbias must be either zero (no bias) or one of [1..7]\n")
  quit(save="no",status=1)
}
if(! is.element(opt$bias, c('none','rnaf','cdaf'))) {
  cat("Fragment selection model ('bias') should be one of : ")
  cat("c('none','rnaf','cdaf'). Will exit now.\n")
  quit(save="no",status=1)
}
if(! is.element(opt$errormodel, c('uniform','illumina4','illumina5'))) {
  cat("Error model ('errormodel') should be one of : ")
  cat("c('uniform','illumina4','illumina5'). Will exit now.\n")
  quit(save="no",status=1)
}



## import reads_per_transcript 
reads_per_transcript <-read.table(opt$readsfile,sep=",")[,1]

## now read the fold changes per transcript - default is all ones
if(! is.null(opt$fcfile)) {
  fold_changes <-read.table(opt$fcfile)
} else {
  fold_changes<-matrix(1,nrow = length(reads_per_transcript),ncol=1)
}

num_groups = ncol(fold_changes)
## set the number of replicates correctly
## numreps can be a single number of a space separated list with different
## replicates per group - note we have to do a sanity check before we can use it
if(is.null(opt$numreps)) {
  if(sum(opt$numreps) != sum(opt$gcbias) ) {
    cat("Number of groups implied by numreps != groups implied by gcbias. ")
    cat("Will exit now.n")
    quit(save="no",status=1)
  }
} else {
  nr <- sapply(strsplit(opt$numreps," ")[[1]], strtoi, simplify=TRUE)
  opt$numreps <-nr
  if((length(nr) != num_groups) && num_groups > 1) {
    cat("Number of groups implied by numreps != columns in fold change. ")
    cat("Will exit now.n")
    quit(save="no",status=1)
  } else{ ## no FC was specified , so set it to 1 for all num_reps
    fold_changes<-matrix(1,nrow = length(reads_per_transcript),ncol=length(nr))
  }
  ## check for consistency now
  if((length(opt$gcbias) != sum(nr)) && length(opt$gcbias)>1) {
    cat("Length of gcbias must be equal to the sum of numreps\n")
    quit(save="no",status=1)
  } else {
    opt$gcbias <- rep(opt$gcbias,sum(nr))
  }

}

################################################################################
## now simulate
simulate_experiment(
  fasta = opt$fastafile,
  gtf = NULL,
  seqpath = NULL,
  outdir = opt$outdir,
  num_reps = opt$numreps,
  reads_per_transcript = reads_per_transcript,
  fold_changes = fold_changes,
  paired = opt$paired,
  error_rate = opt$errorrate,
  gcbias = opt$gcbias,
  strand_specific = opt$strandspec,
  meanmodel = opt$meanmodel,
  writeinfo = opt$writeinfo,
  seed = opt$seed,
  readlen = opt$readlen,
  distr = opt$distr,
  fraglen = opt$fraglen,
  fragsd = opt$fragsd
)

