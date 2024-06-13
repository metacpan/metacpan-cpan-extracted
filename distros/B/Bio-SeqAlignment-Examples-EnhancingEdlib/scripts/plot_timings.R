library(data.table)
library(ggplot2)
library(mgcv)
library(viridis)
library(gratia)
library(patchwork)
rm(list = ls())
dat <- fread("timings.txt")
datOpenMP <- fread("timings_openMP.txt")
txtsize = 2
ggplot(dat, aes(
  x = Workers,
  y = Time,
  color = factor(Chunk_Size)
)) + geom_point(size = 0.5) +
  geom_line(linewidth = 0.4) +
  scale_y_continuous(trans = 'log2', breaks = c(8, 16, 32, 64, 128, 256))  + theme_bw() + theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.text.x = element_text(size = 8),
    legend.position="bottom"
  ) + scale_color_viridis_d(name = "Chunk Size") +
  scale_x_continuous(
    trans = 'log2',
    breaks = c(1, 2, 4, 8, 12, 18, 27, 36, 45, 54, 63, 72)
  )  +
  geom_vline(
    xintercept = c(18, 36, 54, 72),
    linetype = "dashed",
    color = "gray40"
  ) +
  annotate(
    "segment",
    x = 36,
    xend = 72,
    y = 32,
    yend = 32,
    color = "gray80",
    arrow = arrow(
      type = "open",
      ends = "both",
      length = unit(0.1, "inches")
    )
  ) +
  geom_vline(
    xintercept = c(18, 36, 54, 72),
    linetype = "dashed",
    color = "gray40"
  ) +
  annotate(
    "text",
    x = 17,
    y = 128,
    label = "NUMA limit",
    hjust = 1
  ) +
  annotate(
    "text",
    x = 54,
    y = 38,
    label = "HYPERTHREADS",
    hjust = 0.6,
    lineheight = 0.5,
    size = txtsize * 1.2
  ) +
  annotate(
    "text",
    x = 8,
    y = 70,
    label = "node 0",
    hjust = 0.5,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 24,
    y = 70,
    label = "node 1",
    hjust = 0.2,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 41,
    y = 70,
    label = "node 0",
    hjust = 0.0,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 56,
    y = 70,
    label = "node 1",
    hjust = 0,
    size = txtsize
  )+
xlab("Number of Workers") + ylab("Time (seconds)")
ggsave(
  "timings_chunk.png",
  width = 6,
  height = 4,
  units = "in",
  dpi = 1200
)
dat1 <- dat[Chunk_Size == 1]

f <- gam(log2(Time) ~ s(log2(Workers), bs = "ts"), data = dat1)
pr <- predict(f, se = TRUE, type = "response")
dat1$pr = 2 ^ pr$fit
dat1$prmin = 2 ^ (pr$fit - 1.96 * pr$se.fit)
dat1$prmax = 2 ^ (pr$fit + 1.96 * pr$se.fit)
txtsize = 2
ggplot(dat1, aes(x = Workers, y = Time)) + geom_point(size = 0.3, color =
                                                        "red") +
  geom_line(
    data = dat1,
    aes(x = Workers, y = pr),
    color = "black",
    linewidth = 0.4
  ) +
  geom_ribbon(data = dat1,
              aes(x = Workers, ymin = prmin, ymax = prmax),
              alpha = 0.2) +
  theme_bw() + theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.text.x = element_text(size = 8)
  ) +
  scale_y_continuous(trans = 'log2', breaks = c(8, 16, 32, 64, 128, 256)) +
  scale_x_continuous(
    trans = 'log2',
    breaks = c(1, 2, 4, 8, 12, 18, 27, 36, 45, 54, 63, 72)
  )  +
  geom_vline(
    xintercept = c(18, 36, 54, 72),
    linetype = "dashed",
    color = "gray40"
  ) +
  annotate(
    "segment",
    x = 36,
    xend = 72,
    y = 32,
    yend = 32,
    color = "gray80",
    arrow = arrow(
      type = "open",
      ends = "both",
      length = unit(0.1, "inches")
    )
  ) +
  geom_vline(
    xintercept = c(18, 36, 54, 72),
    linetype = "dashed",
    color = "gray40"
  ) +
  annotate(
    "text",
    x = 17,
    y = 128,
    label = "NUMA limit",
    hjust = 1
  ) +
  annotate(
    "text",
    x = 54,
    y = 38,
    label = "HYPERTHREADS",
    hjust = 0.6,
    lineheight = 0.5,
    size = txtsize * 1.2
  ) +
  annotate(
    "text",
    x = 8,
    y = 70,
    label = "node 0",
    hjust = 0.5,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 24,
    y = 70,
    label = "node 1",
    hjust = 0.2,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 41,
    y = 70,
    label = "node 0",
    hjust = 0.0,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 56,
    y = 70,
    label = "node 1",
    hjust = 0,
    size = txtsize
  )+
  xlab("Number of Workers") + ylab("Time (seconds)")
ggsave(
  "timings.png",
  width = 6,
  height = 4,
  units = "in",
  dpi = 1200
)
################################################################################
## combine openMP and MCE timings
dat1$Type <- "MCE"
datOpenMP$Type <- "OpenMP"
dat1$TotWorkers <- dat1$Workers
datOpenMP$TotWorkers <- datOpenMP$Workers * datOpenMP$Num_threads

datOMPCME <-
  rbind(dat1[, c("Time", "Type", "TotWorkers", "Workers")],
        datOpenMP[Workers == 1, c("Time", "Type", "TotWorkers", "Workers")])
datOMPCME$Type <-
  factor(datOMPCME$Type, levels = c("MCE", "OpenMP"))

quantile(datOMPCME$TotWorkers, c(0.05,0.1, 0.9))
f2 <-
  gam(log2(Time) ~ s(log2(TotWorkers), bs = "ts", by = Type) + Type, data = datOMPCME)


pr2 <- predict(f2, se = TRUE, type = "response")
datOMPCME$pr2 = 2 ^ pr2$fit
datOMPCME$prmin2 = 2 ^ (pr2$fit - 1.96 * pr2$se.fit)
datOMPCME$prmax2 = 2 ^ (pr2$fit + 1.96 * pr2$se.fit)
txtsize = 2


ggplot(datOMPCME, aes(x = TotWorkers, y = Time, shape = Type)) +
  geom_point(size = 0.5, color = "red") +
  geom_line(
    data = datOMPCME,
    aes(x = TotWorkers, y = pr2),
    color = "black",
    linewidth = 0.4
  ) +
  geom_ribbon(data = datOMPCME,
              aes(x = TotWorkers, ymin = prmin2, ymax = prmax2),
              alpha = 0.2) +
  theme_bw() + theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.text.x = element_text(size = 8),
    legend.position="bottom"
  ) + 
  scale_y_continuous(trans = 'log2', breaks = c(8, 16, 32, 64, 128, 256)) +
  scale_x_continuous(
    trans = 'log2',
    breaks = c(1, 2, 4, 8, 12, 18, 27, 36, 45, 54, 63, 72)
  )  +
  geom_vline(
    xintercept = c(18, 36, 54, 72),
    linetype = "dashed",
    color = "gray40"
  ) +
  annotate(
    "segment",
    x = 36,
    xend = 72,
    y = 32,
    yend = 32,
    color = "gray80",
    arrow = arrow(
      type = "open",
      ends = "both",
      length = unit(0.1, "inches")
    )
  ) +
  geom_vline(
    xintercept = c(18, 36, 54, 72),
    linetype = "dashed",
    color = "gray40"
  ) +
  annotate(
    "text",
    x = 17,
    y = 128,
    label = "NUMA limit",
    hjust = 1
  ) +
  annotate(
    "text",
    x = 54,
    y = 38,
    label = "HYPERTHREADS",
    hjust = 0.6,
    lineheight = 0.5,
    size = txtsize * 1.2
  ) +
  annotate(
    "text",
    x = 8,
    y = 70,
    label = "node 0",
    hjust = 0.5,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 24,
    y = 70,
    label = "node 1",
    hjust = 0.2,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 41,
    y = 70,
    label = "node 0",
    hjust = 0.0,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 56,
    y = 70,
    label = "node 1",
    hjust = 0,
    size = txtsize
  )+
  xlab("Number of Workers") + ylab("Time (seconds)")
ggsave(
  "timings_MCE_OMP.png",
  width = 6,
  height = 4,
  units = "in",
  dpi = 1200
)
################################################################################
## now analyze the cost of memory for a given sec of performance

f3 <-
  gam(log2(Workers * Time) ~ s(log2(TotWorkers), bs = "ts", by = Type) + Type, data = datOMPCME)


pr3 <- predict(f3, se = TRUE, type = "response")
datOMPCME$pr3 = 2 ^ pr3$fit
datOMPCME$prmin3 = 2 ^ (pr3$fit - 1.96 * pr3$se.fit)
datOMPCME$prmax3 = 2 ^ (pr3$fit + 1.96 * pr3$se.fit)
txtsize = 2


ggplot(datOMPCME, aes(x = TotWorkers, y = Workers * Time, shape = Type)) +
  geom_point(size = 0.5, color = "red") +
  geom_line(
    data = datOMPCME,
    aes(x = TotWorkers, y = pr3),
    color = "black",
    linewidth = 0.4
  ) +
  geom_ribbon(data = datOMPCME,
              aes(x = TotWorkers, ymin = prmin3, ymax = prmax3),
              alpha = 0.2) +
  theme_bw() + theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.text.x = element_text(size = 8),
    legend.position="bottom"
  ) + 
  scale_y_continuous(trans = 'log2',breaks =2^(4:9)) +
  geom_segment(
    x = log2(36),
    xend = log2(72),
    y = log2(32),
    yend = log2(32),
    color = "gray80",
    arrow = arrow(
      type = "open",
      ends = "both",
      length = unit(0.1, "inches")
    )
  ) +
  scale_x_continuous(
    trans = 'log2',
    breaks = c(1, 2, 4, 8, 12, 18, 27, 36, 45, 54, 63, 72)
  )  +
  geom_vline(
    xintercept = c(18, 36, 54, 72),
    linetype = "dashed",
    color = "gray40"
  ) +
  annotate(
    "segment",
    x = 36,
    xend = 72,
    y = 32,
    yend = 32,
    color = "gray80",
    arrow = arrow(
      type = "open",
      ends = "both",
      length = unit(0.1, "inches")
    )
  ) +
  geom_vline(
    xintercept = c(18, 36, 54, 72),
    linetype = "dashed",
    color = "gray40"
  ) +
  annotate(
    "text",
    x = 17,
    y = 128,
    label = "NUMA limit",
    hjust = 1
  ) +
  annotate(
    "text",
    x = 54,
    y = 38,
    label = "HYPERTHREADS",
    hjust = 0.6,
    lineheight = 0.5,
    size = txtsize * 1.2
  ) +
  annotate(
    "text",
    x = 8,
    y = 70,
    label = "node 0",
    hjust = 0.5,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 24,
    y = 70,
    label = "node 1",
    hjust = 0.2,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 41,
    y = 70,
    label = "node 0",
    hjust = 0.0,
    size = txtsize
  ) +
  annotate(
    "text",
    x = 56,
    y = 70,
    label = "node 1",
    hjust = 0,
    size = txtsize
  )+
  xlab("Number of Workers") + ylab("Resource Use ( cp x s)")
ggsave(
  "spacetime_MCE_OMP.png",
  width = 6,
  height = 4,
  units = "in",
  dpi = 1200
)
################################################################################
datOpenMP$SpaceTime <- datOpenMP$Time * datOpenMP$Workers

## fit for time
f4<-gam(log2(Time)~ti(log2(Workers),bs="ts")+
          ti(log2(Num_threads),bs="ts")+
          ti(log2(Workers),log2(Num_threads),bs="ts"),data=datOpenMP)
datOpenMP$fitTime <- predict(f4,type="response")

## fit for space time
f5<-gam(log2(SpaceTime)~ti(log2(Workers),bs="ts")+
          ti(log2(Num_threads),bs="ts")+
          ti(log2(Workers),log2(Num_threads),bs="ts"),data=datOpenMP)
datOpenMP$fitSpaceTime <-predict(f5,type="response")

## find the 5% rows with the smallest Time & SpaceTime in the datOpenMP data
minTime<-datOpenMP[order(Time)][1:round(nrow(datOpenMP)*0.05)]
minSpaceTime<-datOpenMP[order(Time*Workers)][1:round(nrow(datOpenMP)*0.05)]

## find the row with the minimum Time in datOpenMP
minTime<-datOpenMP[which.min(datOpenMP$Time),]

## three dimensional plots as contourplots

ggplot(datOpenMP, aes(x = Workers, y = Num_threads, z = fitTime)) +
  geom_contour(aes(colour = after_stat(level))) +theme_bw() + theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.text.x = element_text(size = 8),
    legend.position="bottom"
  ) + 
  scale_color_viridis(discrete=FALSE,name="Time (log2 sec)") +
  geom_point(data=minTime,aes(x=Workers,y=Num_threads),color="black",shape="+")+
  scale_y_continuous(trans = 'log2', breaks = c(1, 2, 4, 8, 18, 36,72)) +
  scale_x_continuous(trans = 'log2', breaks = c(1, 2, 4, 8, 18, 36,72)) +
  xlab("Number of Workers") + ylab("Number of Threads")

ggsave(
  "timings_MCE_with_OMP.png",
  width = 6,
  height = 6.5,
  units = "in",
  dpi = 1200
)

ggplot(datOpenMP, aes(x = Workers, y = Num_threads, z = fitSpaceTime)) +
  geom_contour(aes(colour = after_stat(level))) +theme_bw() + theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.text.x = element_text(size = 8),
    legend.position="bottom"
  ) + 
  scale_color_viridis(discrete=FALSE,name="Resource Use ( cp x s)") +
  geom_point(data=minSpaceTime,aes(x=Workers,y=Num_threads),color="black",shape="+")+
  scale_y_continuous(trans = 'log2', breaks = c(1, 2, 4, 8, 18, 36,72)) +
  scale_x_continuous(trans = 'log2', breaks = c(1, 2, 4, 8, 18, 36,72)) +
  xlab("Number of Workers") + ylab("Number of Threads")
ggsave(
  "spacetime_MCE_with_OMP.png",
  width = 6,
  height = 6.5,
  units = "in",
  dpi = 1200
)
################################################################################
## make a copy to replot the statistical model for the data
datOpenMP_log2<-datOpenMP
datOpenMP_log2$Time<-log2(datOpenMP_log2$Time)
datOpenMP_log2$Workers<-log2(datOpenMP_log2$Workers)
datOpenMP_log2$Num_threads<-log2(datOpenMP_log2$Num_threads)

f4_log2<-gam(Time~ti(Workers,bs="ts")+ti(Num_threads)+ti(Workers,Num_threads,bs="ts"),data=datOpenMP_log2)

predTerms<-predict(f4_log2,type="terms",se.fit=TRUE)

datOpenMP_log2$Weff<-predTerms$fit[,1]
datOpenMP_log2$Weffmin<-predTerms$fit[,1]-1.96*predTerms$se.fit[,1]
datOpenMP_log2$Weffmax<-predTerms$fit[,1]+1.96*predTerms$se.fit[,1]

datOpenMP_log2$Teff<-predTerms$fit[,2]
datOpenMP_log2$Teffmin<-predTerms$fit[,2]-1.96*predTerms$se.fit[,2]
datOpenMP_log2$Teffmax<-predTerms$fit[,2]+1.96*predTerms$se.fit[,2]

datOpenMP_log2$WeffTeff<-predTerms$fit[,3]
datOpenMP_log2$WeffTeffmin<-predTerms$fit[,3]-1.96*predTerms$se.fit[,3]
datOpenMP_log2$WeffTeffmax<-predTerms$fit[,3]+1.96*predTerms$se.fit[,3]

png("Worker_Thread_interaction.png",width=6,height=6,units="in",res=1200,pointsize=10)
par(xaxt="n",yaxt="n")
plot(f4_log2,select=3,se=F,rug=FALSE,main = "Worker x Thread Interaction",
     xlab = "Workers (log2)",ylab="Threads (log2)")
par(xaxt="s")
axis(1,at=log2(c(1, 2, 4, 8, 18, 36,72)),labels=c(1, 2, 4, 8, 18, 36,72))
par(yaxt="s")
axis(2,at=log2(c(1, 2, 4, 8, 18, 36,72)),labels=c(1, 2, 4, 8, 18, 36,72))
dev.off()

tick<-c(1, 2, 4, 8, 18, 36,72)
ytick<-seq(0,1.5,length.out=5)
pW<-draw(f4,rug=F,se=T,select=1,xlab="Workers (log2)")+
  scale_y_continuous(breaks=ytick)+
  scale_x_continuous(breaks=log2(tick),labels=tick)+
  theme_bw() + theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.text.x = element_text(size = 8),
    plot.title = element_text(hjust=0.5)
  )  +
  ggtitle("Workers Effect")+
  xlab("Workers (log2)") + ylab("Effect on Time (log2 sec)")


ytick<-seq(-0.4,0.4,length.out=5)
pT<-draw(f4,rug=F,se=T,select=2,xlab="Workers (log2)")+
  scale_y_continuous()+
  scale_x_continuous( breaks = log2(tick),labels=tick)+
  theme_bw() + theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.text.x = element_text(size = 8),
    plot.title = element_text(hjust=0.5)
  ) +
  ggtitle("Threads Effect")+
  xlab("Threads (log2)") + ylab("Effect on Time (log2 sec)")


pW+pT+plot_layout(ncol = 2)
ggsave("Worker_Thread_effects.png",width=6,height=4,units="in",dpi=1200,pointsize=10)