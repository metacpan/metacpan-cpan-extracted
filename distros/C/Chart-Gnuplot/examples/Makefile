IMAGES = \
axisLabel_1.png \
axisLabel_2.png \
axisLabel_3.png \
axisLabel_4.png \
axisLabel_5.png \
axisLabel_6.png \
axisLabel_7.png \
axisLabel_8.png \
axisTics_1.png \
axisTics_2.png \
axisTics_3.png \
axisTics_4.png \
axisTics_5.png \
axisTics_6.png \
axisTics_7.png \
axisTics_8.png \
axisTics_9.png \
axisTics_10.png \
axisTics_11.png \
axisTics_12.png \
axisTics_13.png \
background_1.png \
background_2.png \
border_1.png \
border_2.png \
border_3.png \
chartDim_1.png \
chartDim_2.png \
chartDim_3.png \
chartFmt_1.png \
chartFmt_2.png \
chartFmt_3.png \
chartFmt_4.png \
chartTitle_1.png \
chartTitle_2.png \
chartTitle_3.png \
chartTitle_4.png \
chartTitle_5.png \
chartTitle_6.png \
chartTitle_7.png \
chartTitle_8.png \
dataSrc_1.png \
dataSrc_2.png \
dataSrc_3.png \
dataSrc_4.png \
dataSrc_5.png \
dataSrc_6.png \
datetime_1.png \
datetime_2.png \
datetime_3.png \
grid_1.png \
grid_2.png \
grid_3.png \
grid_4.png \
grid_5.png \
grid_6.png \
grid_7.png \
grid_8.png \
grid_9.png \
legend_1.png \
legend_2.png \
legend_3.png \
legend_4.png \
legend_5.png \
legend_6.png \
legend_7.png \
legend_8.png \
legend_9.png \
legend_10.png \
lineStyle_1.png \
lineStyle_2.png \
lineStyle_3.png \
lineStyle_4.png \
lineStyle_5.png \
multiplot_1.png \
multiplot_2.png \
multiplot_3.png \
plot3d_1.png \
plot3d_2.png \
plot3d_3.png \
plot3d_4.png \
plotAxes_1.png \
plotAxes_2.png \
plotStyle_1.png \
plotStyle_2.png \
plotStyle_3.png \
plotStyle_4.png \
plotStyle_5.png \
plotStyle_6.png \
plotStyle_7.png \
plotStyle_8.png \
plotStyle_9.png \
plotStyle_10.png \
plotStyle_11.png \
plotStyle_12.png \
plotStyle_13.png \
plotStyle_14.png \
plotStyle_15.png \
range_1.png \
range_2.png \
range_3.png \

all: mkdir $(IMAGES)

mkdir:
	@mkdir -p gallery

%.png: %.pl
	@echo "Plotting $@"
	@perl $<

clean:
	@rm -f *~
	@-cd gallery; rm -f $(IMAGES)
