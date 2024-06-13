library(dqrng)
library(data.table)
library(vioplot)
library(microbenchmark)
rm(list=ls());gc()
simtrunceval<-function(n,distr=NULL,uniformRNG=NULL,lower=NULL,upper=NULL,...){
  cdf<-function(x,...) eval(parse(text=paste("p",distr,sep="")))(x,...)
  invcdf<-function(x,...) eval(parse(text=paste("q",distr,sep="")))(x,...)
  uniform = function(x,...) eval(parse(text=uniformRNG))(x)
  lowercdf <-ifelse(is.null(lower),0,cdf(lower,...))
  uppercdf <-ifelse(is.null(upper),1,cdf(upper,...))
  domain <-uppercdf - lowercdf
  simvals<-uniform(n)
  simvals<-lowercdf + simvals*domain
  invcdf(simvals,...)
}

simtruncget<-function(n,distr=NULL,uniformRNG=NULL,lower=NULL,upper=NULL,...){
  cdf<-get(paste("p", distr, sep = ""))
  invcdf<-get(paste("q", distr, sep = ""))
  uniform = get(uniformRNG)
  lowercdf <-ifelse(is.null(lower),0,cdf(lower,...))
  uppercdf <-ifelse(is.null(upper),1,cdf(upper,...))
  domain <-uppercdf - lowercdf
  simvals<-uniform(n)
  simvals<-lowercdf + simvals*domain
  invcdf(simvals,...)
}

simtruncfixedrunif<-function(n,lower=NULL,upper=NULL,...){
  lowercdf <-ifelse(is.null(lower),0,plnorm(lower,...))
  uppercdf <-ifelse(is.null(upper),1,plnorm(upper,...))
  domain <-uppercdf - lowercdf
  simvals<-runif(n)
  simvals<-lowercdf + simvals*domain
  qlnorm(simvals,...)
}

simtruncfixedqrng<-function(n,lower=NULL,upper=NULL,...){
  lowercdf <-ifelse(is.null(lower),0,plnorm(lower,...))
  uppercdf <-ifelse(is.null(upper),1,plnorm(upper,...))
  domain <-uppercdf - lowercdf
  simvals<-dqrunif(n)
  simvals<-lowercdf + simvals*domain
  qlnorm(simvals,...)
}

simnontruncget<-function(n,distr=NULL,...){
  sim<-get(paste("r", distr, sep = ""))
  sim(n,...)
}


dqRNGkind("Xoshiro256+")
iter = 1000000
times<-1000
distr="lnorm"
leftrunc=0
rightrunc=250
param1=log(125)
param2=1
timeunif<-microbenchmark(vals<-simtrunceval(iter,distr,'runif',leftrunc,rightrunc,param1,param2),times=times)
timeunifget<-microbenchmark(valsget<-simtruncget(iter,distr,'runif',leftrunc,rightrunc,param1,param2),times=times)
timedruniffixed<-microbenchmark(valsd<-simtruncfixedrunif(iter,leftrunc,rightrunc,param1,param2),times=times)
timedqrunif<-microbenchmark(valsd<-simtrunceval(iter,distr,'dqrunif',leftrunc,rightrunc,param1,param2),times=times)
timedqrunifget<-microbenchmark(valsdget<-simtruncget(iter,distr,'dqrunif',leftrunc,rightrunc,param1,param2),times=times)
timedqruniffixed<-microbenchmark(valsd<-simtruncfixedqrng(iter,leftrunc,rightrunc,param1,param2),times=times)
time<-microbenchmark(x<-dqrunif(iter),times=times)



## load perl timings
data_folder <- file.path(dirname(rstudioapi::getActiveDocumentContext()$path), "")
perldat <- fread(file.path(data_folder, "testPerl.csv"))
PDL_random = perldat$PDL_random
perldat[,PDL_random:=NULL]

at = seq(-1.6,0,0.1)
nmPerl<-c("PDLGSL_PDLGSLUNIF_WITH_OC","PDLGSL_PDLGSLUNIF_WO_OC",
      "PDLGSL_PDLUNIF_WITH_OC" ,   "PDLGSL_PDLUNIF_WO_OC",     
      "PDLGSL_PERLRNGPDL_WITH_OC", "PDLGSL_PERLRNGPDL_WO_OC",
      "MathMLGSL_PERLRNG_WITH_OC" ,"MathMLGSL_PERLRNG_WO_OC" )
nmR<-toupper(c("unif_eval","unif_get","unif_fixed",
               "dqrunif_eval","dqrunif_get","dqrunif_fixed"))
png("vioplot_Perl_R_lognormal.png",width=8,height=8,units="in",res=1200,pointsize=9)
par(mfrow=c(2,1),mar=c(3,12,2,1)+0.2,xaxt="n",yaxt="n")
vioplot(sapply(list(timeunif$time,timeunifget$time,timedruniffixed$time,
                    timedqrunif$time,  timedqrunifget$time, 
                    timedqruniffixed$time),function(x) log10(x/10^9)),
        xlab="",ylab="",outline=TRUE,main="R timings (log10 sec)",
        ylim=c(at[1],at[length(at)]),horizontal = TRUE,las=1,cex.axis=0.8)
par(xaxt="s",yaxt="s")
axis(1,at=at,las=1,tck = 1, lty = 2, col = "gray",cex.axis=0.8)
axis(2,at=1:length(nmR),labels=nmR,cex.axis=0.8,las=1)
par(xaxt="n",yaxt="n")

vioplot(sapply(perldat[,c("PDLGSL_PDLGSLUNIF_WITH_OC","PDLGSL_PDLGSLUNIF_WO_OC",
                          "PDLGSL_PDLUNIF_WITH_OC" ,   "PDLGSL_PDLUNIF_WO_OC",     
                          "PDLGSL_PERLRNGPDL_WITH_OC", "PDLGSL_PERLRNGPDL_WO_OC",
                          "MathMLGSL_PERLRNG_WITH_OC" ,"MathMLGSL_PERLRNG_WO_OC" )],
               function(x) log10(x)),names = nm,
        xlab="",ylab="",outline=TRUE,main="Perl timings (log10 sec)",
        ylim=c(at[1],at[length(at)]),horizontal = TRUE,las=1,cex.axis=0.8)
par(xaxt="s",yaxt="s")
axis(1,at=at,las=1,tck = 1, lty = 2, col = "gray",cex.axis=0.8)
axis(2,at=1:length(nmPerl),labels=nmPerl,cex.axis=0.8,las=1)
dev.off()

