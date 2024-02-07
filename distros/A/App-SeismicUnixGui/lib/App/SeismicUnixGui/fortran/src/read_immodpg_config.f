      subroutine read_immodpg_config (base_file,results,inbound)
         implicit none
!       read a configuration file

      integer*2 :: result
      character (len=80) :: name, answer
      character (len=30) :: format0,format1,format2,format3
      character (len=30) :: format4,format5,format6
      character (len=30) :: format7,format8,format9
      character (len=30) :: format10,format11,format12,format13
      character (len=30) :: format14,format15,format16,format17
      character (len=30) :: format18,format19
      character (len=5)  :: equal,previous_model,new_model
      character (len=5)  :: pre_digitized_XT_pairs,data_traces
      character (len=40) :: base_file
      character (len=255):: inbound, inbound_locked
      real               :: min_t_s,max_t_s,min_x_m,max_x_m
      real               :: thickness_increment_m
      real               :: data_x_inc_m,source_depth_m,receiver_depth_m
      real               :: reducing_vel_mps,plot_min_x_m,plot_max_x_m
      real               :: plot_min_t_s,plot_max_t_s,VtopNbot_factor
      real               :: Vincrement_mps, clip, m2km
      real*4             :: results(30)
      integer*2          :: layer
      integer            :: err_msg, counter, ready
      
!     in case definition in main is slightly different
!     pre_digitized_XT_pairs = 'no'
!     data_traces = 'no'
!     previous_model = 'no'
!     new_model = 'no'
!     sum of first two character strings= 35
      inbound_locked=trim(inbound)//"_locked"
      format0= "(A14,21X,A1,1X,A)"
      format1= "(A22,13X,A1,1X,A)"
      format2= "(A11,24X,A1,1X,A)"
      format3= "(A4,31X,A1,1X,F5.1)"
      format4= "(A7,28X,A1,1X,F10.3)"
      format5= "(A7,28X,A1,1X,F10.3)"
      format6= "(A13,22X,A1,1X,F10.3)"
      format7= "(A14,21X,A1,1X,F10.3)"
      format8= "(A16,19X,A1,1X,F10.3)"
      format9= format8
      format10="(A12,23X,A1,1X,F10.3)"
      format11= format10
      format12= format10
      format13= format10
      format14= "(A14,21X,A1,1X,A)"
      format15= "(A9,26X,A1,1X,A)"
      format16= "(A5,30X,A1,1X,I2)"
      format17= "(A15,20X,A1,1X,F10.3)"
      format18= "(A14,21X,A1,1X,F10.3)"
      format19= "(A21,14X,A1,1X,F10.3)"
      m2km = .001;

!      print*, 'read_immodpg_config.f, inbound is:', trim(inbound)

!      create a temporary, new, lock file
10     open(status='new',unit=2,file=inbound_locked,iostat=ready)

       if (ready.eq.0) then

        open(unit=1,file=trim(inbound),status='old',iostat=err_msg)

!       check whether file opens data file
        if (err_msg.eq.0) then

         read (1,format0) name,equal,base_file
         base_file = trim(base_file)
 !        print*, '0. read_immodpg_config.f, base file_name:',base_file
         read (1,format1) name,equal,pre_digitized_XT_pairs
!        print*, '1. read_immodpg_config.f, pre_digitized_XT_pairs:',
!     +  pre_digitized_XT_pairs
         read (1,format2) name,equal,data_traces
!       print*, '2. read_immodpg_config.f, data_traces:',data_traces
         read (1,format3) name,equal,clip
!       print*, '3. read_immodpg_config.f, clip:',clip
         read (1,format4) name,equal,min_t_s
         read (1,format5) name,equal,min_x_m
         read (1,format6) name,equal,data_x_inc_m
         read (1,format7) name,equal,source_depth_m
         read (1,format8) name,equal,receiver_depth_m
         read (1,format9) name,equal,reducing_vel_mps
         read (1,format10) name,equal,plot_min_x_m
         read (1,format11) name,equal,plot_max_x_m
         read (1,format12) name,equal,plot_min_t_s
         read (1,format13) name,equal,plot_max_t_s
!      print*, '4. read_immodpg_config.f, min_t_s:',min_t_s
!      print*, '5. read_immodpg_config.f, min_x_m:',min_x_m
!      print*, '6. read_immodpg_config.f, data_x_inc_m:',
!     + real(data_x_inc_m)
!      print*, '7. read_immodpg_config.f, source_depth_m:',
!     + source_depth_m
!      print*,'8. read_immodpg_config.f,receiver_depth_m:',
!     + receiver_depth_m
!        print*,'9. read_immodpg_config.f, reducing_vel_mps:',+ reducing_vel_mps
!       print*, '10. read_immodpg_config.f, plot_min_x_m:',plot_min_x_m
!       print*, '11. read_immodpg_config.f, plot_max_x_m:',plot_max_x_m
!       print*, '12.read_immodpg_config.f, plot_min_t_s:',plot_min_t_s
!       print*, '13. read_immodpg_config.f, plot_max_t_s:',plot_max_t_s
         read (1,format14) name,equal,previous_model
!       print*, '14.read_immodpg_config.f, previous_model:',
!     +previous_model,'--'
         read (1,format15) name,equal,new_model
!       print*, '15.read_immodpg_config.f, new_model:',new_model
         read (1,format16) name,equal,layer
!       print*,'16.read_immodpg_config.f, layer:',
!     + layer
         read (1,format17) name,equal,VtopNbot_factor
!       print*,'17.read_immodpg_config.f, ,VtopNbot_factor:'
!     + ,VtopNbot_factor
         read (1,format18) name,equal,Vincrement_mps
!       print*,'18.read_immodpg_config.f,Vincrement_mps:'
!     + ,Vincrement_mps
         read (1,format19) name,equal,thickness_increment_m
!       print*,'19.read_immodpg_config.f,thickness_increment_m:'
!     + ,thickness_increment_m
         if (base_file .ne. '') then
!        print*, 'Found it,read_immodpg_config.f, base_file:',base_file
         else
          print*, 'read_immodpg_config.f, base_file missing:'
         end if

         if (pre_digitized_XT_pairs == 'yes') then
          results(1) = 1.
         else
          results(1) = 0.
         end if

         if (data_traces == 'yes') then
          results(2) = 1.
         else
          results(2) = 0.
         end if

         results(3) = real(clip)
         results(4) = min_t_s
         results(5) = min_x_m * m2km
         results(6) = real(data_x_inc_m) * m2km
         results(7) = source_depth_m * m2km
         results(8) = receiver_depth_m * m2km
         results(9) = reducing_vel_mps * m2km
         results(10) = plot_min_x_m * m2km
         results(11) = plot_max_x_m * m2km
         results(12) = plot_min_t_s
         results(13) = plot_max_t_s

         if (previous_model == 'yes') then
          results(14) = 1.
!        print*,'2.read_immodpg_config.f,previous_model=', results(14)
         else
          results(14) = 0.
!        print*,'2.read_immodpg_config.f,previous_model',results(14)
         end if

          if (new_model == 'yes') then
           results(15) = 1.
         else
           results(15) = 0.
         end if

         if (layer >= 0.0 ) then
           results(16) = real(layer)
!       print*,'1. read_immodpg_config.f,_layer:',layer
         else
          results(16) = -1.00
!      print*,'2.read_immodpg_config.f,layer:',layer
         end if

         results(17) = VtopNbot_factor;
         results(18) = Vincrement_mps * m2km;
         results(19) = thickness_increment_m * m2km;
!       result = 1
       close (unit=1)
!      if (answer == 'yes')

!      print(*), 'bingo=',result
!      end if

         else
!         print *, 'read_immodpg_file.f, err_msg=',err_msg
!         print *, 'read_immodpg_file.f, counter=',counter
!         rest a little before trying again
!         call sleep(1)
          go to 10
         end if
       else
        print *, 'read_immodpg_config.f,locked,try again,ready=',ready
!         go to 10
       end if
!       remove lock file
11      close (status='delete',unit=2,iostat=err_msg)
        if (err_msg.ne.0) then
         go to 11
         print *, 'read_immodpg_file.f, err_messg=',err_msg
        end if
!       print *, 'read_immodpg_file, result',result

      end subroutine read_immodpg_config
