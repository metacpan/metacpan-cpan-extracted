      subroutine read_thickness_increment_m_file(result,inbound)
         implicit none
!       read a configuration file

      integer :: result
      character (len=255) :: inbound, inbound_locked
      character (len=30) :: format1
      integer :: err_msg, ready

      inbound_locked=trim(inbound)//"_locked"
      format1= "(F5.1)"

!      print *, 'read_thickness_increment_m_file.f, inbound is:', trim(inbound)
!      in case inbound is of a different, but shorter length in main
!      create a temporary, new, lock file
10     open(status='new',unit=30,file=inbound_locked,iostat=ready)

       if (ready.eq.0) then
         open(unit=29,file=trim(inbound),status='old',iostat=err_msg)
 !       check whether file opens data file
         if (err_msg.eq.0) then

          read (29,format1) result
!          print *, 'read_thickness_increment_m_file.f, result',result
          close (unit=29)

         else
          print *, 'read_thickness_increment_m_file.f,locked, try again,read =',ready
!         rest a little before trying again
!         call sleep(1)
          go to 10
         end if

!       remove lock file
11      close (status='delete',unit=30,iostat=err_msg)
        if (err_msg.ne.0) then
         go to 11
!         print *, 'read_thickness_increment_m_file.f, err_messg=',
!     +  err_msg
        end if

       end if
       print *, 'read_thickness_increment_m_file, result',result
      end subroutine read_thickness_increment_m_file
